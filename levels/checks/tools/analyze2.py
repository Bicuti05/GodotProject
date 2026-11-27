import json,glob,re,csv,collections,importlib.util,sys,os
import numpy as np,pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.isotonic import IsotonicRegression
RW='/tmp/claude-0/-home-user-GodotProject/789c606f-fe6b-525e-85bc-e2eb0b400faa/scratchpad/research_work/solver'
spec=importlib.util.spec_from_file_location('build',RW+'/build.py'); build=importlib.util.module_from_spec(spec); spec.loader.exec_module(build)
C='/tmp/claude-0/chk2'
def prep(df):
    df=df.copy()
    df['lw']=df[['ge_e30_win','ge_e45_win','ge_e60_win','ge_sm4_win']].mean(axis=1)
    df['ld']=df[['ge_e30_done','ge_e45_done','ge_e60_done','ge_sm4_done']].mean(axis=1)
    df['beam_logw']=np.log(df.beam_w.clip(upper=200)); return df
tr=prep(pd.read_csv(RW+'/features.csv').merge(pd.read_csv(RW+'/greedy_feat.csv'),on='uid'))
med=tr.opt_len.median(); tr['opt_len']=tr.opt_len.fillna(med)
F5=['lw','ld','rand_win','beam_logw','opt_len']
m5=LinearRegression().fit(tr[F5],tr.score); iso=IsotonicRegression(increasing=False,out_of_bounds='clip').fit(tr.lw,tr.score)
TABLE=[(0.001,0.05,69.5),(0.05,0.15,58.3),(0.15,0.3,44.2),(0.3,0.5,30.6),(0.5,0.7,20.0),(0.7,1.0,10.2)]
def table_mid(lw):  # bin-mean lookup as in README 5.1
    for a,b,v in TABLE:
        if lw<=b: return v
    return 10.2
def interp(lw):    # generator's method: interpolate between bin mid-points, clipped 10.2..69.5
    xs=[(a+b)/2 for a,b,_ in TABLE]; ys=[v for *_,v in TABLE]
    return float(np.interp(lw,xs,ys))
ge=[];out=[]
for f in sorted(glob.glob(C+'/ge_*.json')): ge+=json.load(open(f))
for f in sorted(glob.glob(C+'/out_*.json')): out+=json.load(open(f))
g=[]
for x in ge:
    r={'uid':x['uid']}
    for n,c in zip(['e30','e45','e60','sm4'],x['cfg']):
        s=c['seeds']; r[f'ge_{n}_win']=np.mean([q['win'] for q in s]); r[f'ge_{n}_done']=np.mean([q['done'] for q in s])
    g.append(r)
df=pd.DataFrame(g)
if out: df=df.merge(pd.DataFrame([build.row(x) for x in out]),on='uid',how='left')
df=prep(df) if 'beam_w' in df else df.assign(lw=df[['ge_e30_win','ge_e45_win','ge_e60_win','ge_sm4_win']].mean(axis=1),ld=df[['ge_e30_done','ge_e45_done','ge_e60_done','ge_sm4_done']].mean(axis=1))
if 'opt_len' in df: df['opt_len']=df.opt_len.fillna(med)
ok=df[F5].notna().all(axis=1) if set(F5)<=set(df) else pd.Series(False,index=df.index)
df['est_5f']=np.nan; df.loc[ok,'est_5f']=m5.predict(df.loc[ok,F5]); df['est_5f']=df.est_5f.clip(0,100)
df['est_iso']=iso.predict(df.lw); df['est_tab']=df.lw.map(table_mid); df['est_interp']=df.lw.map(interp)
inp={x['uid']:x['raw'] for x in json.load(open(C+'/in.json'))}
order=json.load(open(C+'/order.json'))
val={}
for line in open(C+'/validate.log',encoding='utf-8',errors='ignore'):
    m=re.match(r'LEVEL id=(\d+)(?:\.0)? valid=(\w+)(?: solvable=(\w+) expanded=(\d+))?(?: errors=(.*))?',line.strip())
    if m: val[order[int(m.group(1))-1]]=dict(valid=m.group(2)=='true',solvable=m.group(3) or '',errors=(m.group(5) or '').strip())
def static(raw):
    pots=collections.Counter(); types=set(); hidden=0; hpos=[]; locks=[]
    for c in raw['initial']+raw['incoming']:
        pot,_,b=c['column'].partition('|'); bs=[t for t in b.split(',') if t]
        if pot not in ('-','x',''): pots[pot]+=1; types.add(int(pot))
        for t in bs:
            if t.startswith('?'): hidden+=1
            types.add(int(t.lstrip('?i')))
        if c.get('columnType')=='unlock': locks.append(c['columnInfo'])
    return dict(n_types=len(types),max_type=max(types) if types else 0,hidden=hidden,locks=len(locks),
        type_lock=sum(1 for L in locks if L.get('condition')=='collect_type'),count_lock=sum(1 for L in locks if L.get('condition')=='collect_count'),
        max_lock_count=max([int(L.get('count',0)) for L in locks],default=0),has_1pot=any(v==1 for v in pots.values()),
        cap=int(raw['capacity']),cups=int(raw['targetCups']),cols=len(raw['initial']))
rows=[]
for uid,raw in inp.items():
    d={'uid':uid}; d.update(static(raw)); d.update(val.get(uid,{})); rows.append(d)
S=pd.DataFrame(rows).merge(df,on='uid',how='left')
def solv(r):
    if r.get('solvable')=='WINNABLE': return 'WINNABLE (DFS)'
    if pd.notna(r.get('beam_w')) and r.get('beam_w')<999: return 'WINNABLE (beam)'
    return 'CHƯA CHỨNG MINH'
S['giai_duoc']=S.apply(solv,axis=1)
S.to_csv(C+'/all_scored.csv',index=False)
# ---------- 1) reliability on held-out Sort Streak boards
meta=json.load(open(C+'/val_meta.json'))
V=S[S.uid.str.startswith('V_')].copy(); V['score']=V.uid.map(lambda u:meta[u]['score']); V['set']=V.uid.map(lambda u:meta[u]['set']); V['level']=V.uid.map(lambda u:meta[u]['level'])
rep={}
def ev(col,d=V):
    e=(d[col]-d.score).dropna(); 
    if len(e)==0: return {}
    from scipy.stats import spearmanr
    return dict(n=int(len(e)),mae=round(e.abs().mean(),2),bias=round(e.mean(),2),sd=round(e.std(),2),r2=round(1-((d[col]-d.score)**2).sum()/((d.score-d.score.mean())**2).sum(),3),rho=round(spearmanr(d[col],d.score,nan_policy='omit')[0],3),within5=round((e.abs()<=5).mean(),3),within10=round((e.abs()<=10).mean(),3))
for col in ['est_5f','est_iso','est_tab','est_interp']: rep[col]=ev(col)
V['bin']=pd.cut(V.score,[-1,10,20,30,40,55,70,101])
rep['by_bin_5f']=V.groupby('bin',observed=True).apply(lambda d:pd.Series(dict(n=len(d),mae=(d.est_5f-d.score).abs().mean(),bias=(d.est_5f-d.score).mean()))).round(2).reset_index().astype(str).values.tolist()
V['hid_grp']=pd.cut(V.hidden,[-1,0,5,10,100],labels=['0','1-5','6-10','>10'])
rep['by_hidden_5f']=V.groupby('hid_grp',observed=True).apply(lambda d:pd.Series(dict(n=len(d),mae=(d.est_5f-d.score).abs().mean(),bias=(d.est_5f-d.score).mean()))).round(2).reset_index().astype(str).values.tolist()
V['lock_grp']=V.locks.clip(upper=2).map({0:'0',1:'1',2:'>=2'})
rep['by_lock_5f']=V.groupby('lock_grp').apply(lambda d:pd.Series(dict(n=len(d),mae=(d.est_5f-d.score).abs().mean(),bias=(d.est_5f-d.score).mean()))).round(2).reset_index().astype(str).values.tolist()
from scipy.stats import spearmanr
rep['resid_vs_hidden_rho']=round(spearmanr(V.hidden,V.est_5f-V.score,nan_policy='omit')[0],3)
rep['resid_vs_locks_rho']=round(spearmanr(V.locks,V.est_5f-V.score,nan_policy='omit')[0],3)
V.to_csv(C+'/validation.csv',index=False)
json.dump(rep,open(C+'/reliability.json','w'),ensure_ascii=False,indent=1)
print(json.dumps(rep,ensure_ascii=False,indent=1))
