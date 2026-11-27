import json,csv,collections,sys
import numpy as np,pandas as pd
from scipy.optimize import linear_sum_assignment
T=float(sys.argv[1]) if len(sys.argv)>1 else 8.0
R=pd.read_csv('/tmp/claude-0/chk/check_result.csv')
inp={x['uid']:x['raw'] for x in json.load(open('/tmp/claude-0/chk/in.json'))}
def stat(raw):
    pots=collections.Counter(); types=set(); hidden=0; tl=cl=0
    for c in raw['initial']+raw['incoming']:
        pot,_,b=c['column'].partition('|'); bs=[t for t in b.split(',') if t]
        if pot not in ('-','x',''): pots[pot]+=1; types.add(int(pot))
        for t in bs:
            hidden+=t.startswith('?'); types.add(int(t.lstrip('?i')))
        if c.get('columnType')=='unlock':
            if c['columnInfo'].get('condition')=='collect_type': tl+=1
            else: cl+=1
    return dict(types=len(types),hidden=hidden,tl=tl,cl=cl,one_pot=any(v==1 for v in pots.values()))
L=R[R.giai_duoc.str.startswith('WINNABLE')].copy()
for k in ['types','hidden','tl','cl','one_pot']: L[k]=[stat(inp[u])[k] for u in L.uid]
L=L.reset_index(drop=True)
def feasible(r,slot,colour_rule):
    if r.hidden>0 and slot<6: return False
    if r.tl>0 and slot<11: return False
    if r.cl>0 and slot<21: return False
    if slot>=13 and (slot-13)%10==0 and not r.one_pot: return False
    if colour_rule and slot>=3 and not (8<=r.types<=10): return False
    return True
def solve(targets,levels,colour_rule):
    cost=np.full((len(targets),len(levels)),1e6)
    for i,(slot,tgt,_) in enumerate(targets):
        for j,r in levels.iterrows():
            if feasible(r,slot,colour_rule):
                e=abs(r.est_5f-tgt); cost[i,j]=e if e<=T else 1000+e
    ri,ci=linear_sum_assignment(cost)
    res=[]
    for i,j in zip(ri,ci):
        slot,tgt,key=targets[i]; r=levels.iloc[j]
        c=cost[i,j]
        res.append(dict(slot=slot,nhom=key,target=tgt,uid=r.uid,nguon=r.set,man_goc=int(r.man),est=round(r.est_5f,1),lech=round(r.est_5f-tgt,1),
                        dung_duoc=c<=T, so_mau=int(r.types),hoa_an=int(r.hidden),khoa_mau=int(r.tl),khoa_so_lan=int(r.cl)))
    return pd.DataFrame(res)
tA=pd.read_csv('/tmp/claude-0/ab/new_level_report.csv',encoding='utf-8-sig')
targetsA=[(int(r.man),float(r.diem_muc_tieu),'A') for r in tA.itertuples() if int(r.man)>=1]
A=solve(targetsA,L,False)
usedA=set(A[A.dung_duoc].uid)
tb=pd.read_csv('/tmp/claude-0/wt_nl/levels/sweet_rope_B/docs/targets_B.csv',encoding='utf-8-sig')
targetsB=[(int(r.slot),float(r.muc_tieu),r.group) for r in tb.itertuples()]
rest=L[~L.uid.isin(usedA)].reset_index(drop=True)
B=solve(targetsB,rest,True)
B=B[B.dung_duoc]
A.to_csv(f'/tmp/claude-0/chk2/assign_A_T{int(T)}.csv',index=False); B.to_csv(f'/tmp/claude-0/chk2/assign_B_T{int(T)}.csv',index=False)
print('T',T,'| A usable',int(A.dung_duoc.sum()),'/200 | from A-set',int((A.dung_duoc&A.nguon.str.startswith('A')).sum()),'from SR',int((A.dung_duoc&A.nguon.str.startswith('SR')).sum()),
      '| A same slot as before',int((A.dung_duoc&A.nguon.str.startswith('A')&(A.man_goc==A.slot)).sum()))
print('B usable groups',len(B),'/680 by set:',collections.Counter(s for g in B.nhom for s in g.split('+')))
print('B by source',B.nguon.value_counts().to_dict(),' unused levels',len(L)-len(usedA)-len(B))
