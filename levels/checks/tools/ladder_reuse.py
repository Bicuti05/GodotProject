# Port of UserLevelLadder.settle (scripts/data/user_level/user_level_ladder.gd) and exact minimum-wins search.
import itertools, collections
N={1:2,2:2,3:3,4:5,5:5}; CAP=5
def settle(level,streak,window,dirty,easy=False,four=False):
    n=N[level]; w=list(window)+[dirty]; w=w[-CAP:]
    streak=0 if dirty else min(streak+1,n)
    losses=sum(w[max(0,len(w)-n):]); wins=min(len(w),n)-losses
    promote = (wins*2>n) if easy else streak>=n
    demote = (losses>=4) if (four and level in (4,5)) else losses*2>n
    new=level
    if promote and level<5: new=level+1
    elif demote and level>1: new=level-1
    if new!=level: return new,0,()
    return level,streak,tuple(w)
def start_states(level,easy,four):
    seen={(0,())}; q=[(0,())]
    while q:
        s,w=q.pop()
        for d in (False,True):
            nl,ns,nw=settle(level,s,w,d,easy,four)
            if nl==level and (ns,nw) not in seen: seen.add((ns,nw)); q.append((ns,nw))
    return seen
def min_wins(ua,ub,easy,four):
    best=10**9
    for (s0,w0) in start_states(ua,easy,four):
        dist={(ua,s0,w0):0}; q=collections.deque([(ua,s0,w0)])
        while q:
            st=q.popleft(); d=dist[st]
            if st[0]==ub: best=min(best,d); break
            for dirty in (False,True):
                nl,ns,nw=settle(*st,dirty,easy,four)
                nst=(nl,ns,nw)
                if nst not in dist: dist[nst]=d+1; q.append(nst)
    return best
def table(rule):
    easy,four=rule
    return {(a,b):min_wins(a,b,easy,four) for a in range(1,6) for b in range(1,6) if a!=b}
rules={'goc':(False,False),'easy_promotion':(True,False)}
tabs={k:table(v) for k,v in rules.items()}
# worst case over rule variants
def worst(a,b): return min(tabs[k][(a,b)] for k in tabs)
print('Số màn thắng TỐI THIỂU để đi từ bậc a sang bậc b (min trên mọi trạng thái xuất phát):')
print('      '+'  '.join(f'->lv{b}' for b in range(1,6)))
for a in range(1,6):
    print(f'lv{a}  '+'  '.join(('  -  ' if a==b else f'{worst(a,b):>4} ') for b in range(1,6)))
# reuse: level at lower slot in set a, at higher slot in set b. served tier = user tier - slack (0 or 1)
def need(a,b,slack):
    best=10**9
    for ua in ([a] + ([a+1] if slack and a<5 else [])):
        for ub in ([b] + ([b+1] if slack and b<5 else [])):
            best=min(best,0 if ua==ub else worst(ua,ub))
    return best
for slack,label in ((0,'KHÔNG có hạ bản (downgrade)'),(1,'CÓ hạ bản 1 bậc (đổi sau 4 lần chơi lại / màn đầu ngày)')):
    print('\n',label,': khoảng cách màn tối đa AN TOÀN (số màn chênh nhau phải NHỎ HƠN số thắng tối thiểu):')
    print('(hàng = bộ ở màn thấp hơn, cột = bộ ở màn cao hơn; "x" = không an toàn ở mọi khoảng cách)')
    print('        '+'  '.join(f'lv{b}' for b in range(1,6)))
    for a in range(1,6):
        row=[]
        for b in range(1,6):
            if a==b: row.append(' x ')
            else:
                m=need(a,b,slack); row.append(' x ' if m==0 else f'{m-1:>3}')
        print(f'lv{a}   '+'  '.join(row))
print('\nví dụ người dùng: màn 20 bộ lv2 -> màn 24 bộ lv5: chênh 4; cần tối thiểu', worst(2,5), 'thắng (không hạ bản) /', need(2,5,1),'(có hạ bản)')
