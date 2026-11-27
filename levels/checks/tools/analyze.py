import json,glob,re,csv,math,collections,importlib.util,sys
import numpy as np,pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.isotonic import IsotonicRegression
from sklearn.model_selection import KFold,cross_val_predict
RW='/tmp/claude-0/-home-user-GodotProject/789c606f-fe6b-525e-85bc-e2eb0b400faa/scratchpad/research_work/solver'
spec=importlib.util.spec_from_file_location('build',RW+'/build.py'); build=importlib.util.module_from_spec(spec); spec.loader.exec_module(build)
# ---- calibration on 392 Sort Streak levels
tr=pd.read_csv(RW+'/features.csv').merge(pd.read_csv(RW+'/greedy_feat.csv'),on='uid')
def prep(df):
    df=df.copy()
    df['lw']=df[['ge_e30_win','ge_e45_win','ge_e60_win','ge_sm4_win']].mean(axis=1)
    df['ld']=df[['ge_e30_done','ge_e45_done','ge_e60_done','ge_sm4_done']].mean(axis=1)
    df['beam_logw']=np.log(df.beam_w.clip(upper=200))
    return df
tr=prep(tr); med_opt=tr.opt_len.median(); tr['opt_len']=tr.opt_len.fillna(med_opt)
F5=['lw','ld','rand_win','beam_logw','opt_len']
m5=LinearRegression().fit(tr[F5],tr.score)
iso=IsotonicRegression(increasing=False,out_of_bounds='clip').fit(tr.lw,tr.score)
# CV error of the two estimators on the calibration set
p5=cross_val_predict(LinearRegression(),tr[F5],tr.score,cv=KFold(5,shuffle=True,random_state=0))
pi=cross_val_predict(IsotonicRegression(increasing=False,out_of_bounds='clip'),tr[['lw']].values.ravel(),tr.score,cv=KFold(5,shuffle=True,random_state=0)) if False else None
calib={'coef5':dict(zip(F5,m5.coef_.round(3))),'intercept5':round(m5.intercept_,2),'cv_mae5':float(np.mean(np.abs(p5-tr.score))),'cv_sd5':float(np.std(p5-tr.score))}
# ---- new levels
C='/tmp/claude-0/chk'
inp={x['uid']:x['raw'] for x in json.load(open(C+'/in.json'))}
ge=[];out=[]
for f in sorted(glob.glob(C+'/ge_*.json')): ge+=json.load(open(f))
for f in sorted(glob.glob(C+'/out_*.json')): out+=json.load(open(f))
g=[]
for x in ge:
    r={'uid':x['uid']}
    for n,c in zip(['e30','e45','e60','sm4'],x['cfg']):
        s=c['seeds']; r[f'ge_{n}_win']=np.mean([q['win'] for q in s]); r[f'ge_{n}_done']=np.mean([q['done'] for q in s])
    g.append(r)
df=pd.DataFrame([build.row(x) for x in out]).merge(pd.DataFrame(g),on='uid',how='outer')
df=prep(df); df['opt_len']=df.opt_len.fillna(med_opt)
ok=df[F5].notna().all(axis=1)
df.loc[ok,'est_5f']=m5.predict(df.loc[ok,F5]); df.loc[df.lw.notna(),'est_lw']=iso.predict(df.loc[df.lw.notna(),'lw'])
# ---- validity from engine log
val={}
for line in open(C+'/validate.log',encoding='utf-8',errors='ignore'):
    m=re.match(r'LEVEL id=(\d+)(?:\.0)? valid=(\w+)(?: solvable=(\w+) expanded=(\d+))?(?: errors=(.*))?',line.strip())
    if m:
        i=int(m.group(1)); uid=('A_%03d'%i) if i<1000 else ('S_%03d'%(i-1000))
        val[uid]=dict(valid=m.group(2)=='true',solvable=m.group(3) or '',dfs_expanded=m.group(4),errors=(m.group(5) or '').strip())
fixed=set()
import os
if os.path.exists(C+'/validate_fix.log'):
    for line in open(C+'/validate_fix.log',encoding='utf-8',errors='ignore'):
        m=re.match(r'LEVEL id=(\d+)(?:\.0)? valid=(\w+)(?: solvable=(\w+) expanded=(\d+))?',line.strip())
        if m:
            uid='S_%03d'%(int(m.group(1))-1000); fixed.add(uid)
            val[uid]['solvable_unity_equiv']=m.group(3) or ''
# ---- targets
tA={int(r['man']):float(r['diem_muc_tieu']) for r in csv.DictReader(open('/tmp/claude-0/ab/new_level_report.csv',encoding='utf-8-sig'))}
tS={int(r['level']):float(r['target_curve']) for r in csv.DictReader(open(C+'/sr_report.csv',encoding='utf-8-sig')) if r['target_curve'] and int(r['level'])<=200}
ss={int(r['level']):float(r['summaryScore']) for r in csv.DictReader(open('/tmp/claude-0/kit/ss_levels.csv',encoding='utf-8-sig')) if r['set']=='default' and int(r['level'])<=200}
# ---- static checks
def parse(col):
    pot,_,beads=col.partition('|'); bs=[b for b in beads.split(',') if b]; return pot,bs
def static(raw,n):
    pots=collections.Counter(); hidden=0; types=set(); locks=[]; ok_types=True
    for c in raw['initial']+raw['incoming']:
        pot,bs=parse(c['column'])
        if pot not in ('-','x',''): pots[pot]+=1; types.add(int(pot))
        for b in bs:
            if b.startswith('?'): hidden+=1
            t=int(b.lstrip('?i')); types.add(t)
        if c.get('columnType')=='unlock': locks.append(c['columnInfo'])
    if any(t>9 for t in types): ok_types=False
    flags=[]
    bonus = n>=13 and (n-13)%10==0
    bonus_ok = any(v==1 for v in pots.values())
    if bonus and not bonus_ok: flags.append('BONUS: không có màu nào chỉ có 1 chậu')
    if hidden and n<6: flags.append('Hoa ẩn trước màn 6')
    for L in locks:
        if L.get('condition')=='collect_type' and n<11: flags.append('Khóa theo màu trước màn 11')
        if L.get('condition')=='collect_count' and n<21: flags.append('Khóa theo số lần trước màn 21')
    if len(locks)>1: flags.append(f'{len(locks)} dây khóa')
    if any(int(L.get('count',0))>3 for L in locks): flags.append('count khóa > 3')
    if not ok_types: flags.append('Loại hoa ngoài 0–9')
    return dict(n_types=len(types),hidden=hidden,locks=len(locks),bonus_slot=bonus,bonus_ok=bonus_ok if bonus else '',cap=raw['capacity'],cups=raw['targetCups'],cols=len(raw['initial']),static_flags='; '.join(flags))
rows=[]
for uid,raw in inp.items():
    s,n=uid[0],int(uid[2:])
    d=dict(set='A (New_Level)' if s=='A' else 'SR_Final (main)',man=n,uid=uid)
    d.update(static(raw,n)); d.update(val.get(uid,{}))
    d['ghi_chu']='Không hợp lệ theo engine Godot (hoa ẩn ở đuôi mục incoming). Độ khó đo trên bản tương đương của Unity (mở sẵn hoa ẩn ở đuôi).' if uid in fixed else ''
    rr=df[df.uid==uid]
    for k in ['lw','ld','rand_win','beam_w','opt_len','est_5f','est_lw','dfs_res']:
        d[k]=rr[k].iloc[0] if len(rr) and k in rr else np.nan
    d['target']=tA.get(n) if s=='A' else tS.get(n,np.nan)
    d['ss_default']=ss.get(n)
    d['err']=d['est_5f']-d['target'] if d['target'] is not None and not pd.isna(d['est_5f']) else np.nan
    rows.append(d)
R=pd.DataFrame(rows).sort_values(['set','man'])
for c in ['est_5f','est_lw']: R[c]=R[c].clip(lower=0,upper=100)
R['err']=R.est_5f-R.target
R['ngoai_vung_hieu_chinh']=((R.cups<10)|(R.n_types<8)|(R.cap<4)).map({True:'có',False:''})
def solv(r):
    if r.get('solvable')=='WINNABLE': return 'WINNABLE (DFS)'
    if r.get('solvable_unity_equiv')=='WINNABLE': return 'WINNABLE (DFS, bản tương đương Unity)'
    if pd.notna(r.get('beam_w')) and r.get('beam_w')<999: return 'WINNABLE (beam)'
    return 'CHƯA CHỨNG MINH'
R['giai_duoc']=R.apply(solv,axis=1)
# duplicates inside each set
def sig(raw): return json.dumps({k:raw[k] for k in ('capacity','targetCups','initial','incoming')},sort_keys=True)
for sname,grp in R.groupby('set'):
    seen=collections.defaultdict(list)
    for _,r in grp.iterrows(): seen[sig(inp[r.uid])].append(r.man)
    for k,v in seen.items():
        if len(v)>1:
            for m in v: R.loc[(R.set==sname)&(R.man==m),'dup_with']=','.join(str(x) for x in v if x!=m)
R.to_csv(C+'/check_result.csv',index=False)
json.dump(calib,open(C+'/calib.json','w'),indent=1)
print(json.dumps(calib,indent=1))
for sname,grp in R.groupby('set'):
    e=grp.err.dropna()
    print('\n==',sname,'n',len(grp),'giai_duoc',dict(collections.Counter(grp.giai_duoc)),'valid',int(grp.valid.sum()) if 'valid' in grp else '?','solvable',dict(collections.Counter(grp.solvable)),
          'lw n',grp.lw.notna().sum())
    print(' MAE %.1f  bias %.1f  |err|>10: %d  >15: %d  >20: %d'%(e.abs().mean(),e.mean(),(e.abs()>10).sum(),(e.abs()>15).sum(),(e.abs()>20).sum()))
    print(' by chapter MAE:',grp.assign(ch=(grp.man-1)//25+1).groupby('ch').err.apply(lambda x:round(x.abs().mean(),1)).to_dict())
    print(' by chapter bias:',grp.assign(ch=(grp.man-1)//25+1).groupby('ch').err.apply(lambda x:round(x.mean(),1)).to_dict())
    fl=grp[grp.static_flags.fillna('')!='']
    print(' static flags:',collections.Counter(f for s in fl.static_flags for f in s.split('; ')).most_common())
    print(' dup layouts:',grp.dup_with.notna().sum() if 'dup_with' in grp else 0)
    print(' n_types:',dict(collections.Counter(grp.n_types)),' cap:',dict(collections.Counter(grp.cap)))
