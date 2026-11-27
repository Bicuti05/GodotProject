"""Python re-implementation of Sort Streak rules (juice_rules.gd) + bot/solver. Mirrors the GDScript; see comments."""
import random, heapq, json
HB, FB = 1000, 2000


def hidden(v): return HB <= v < FB
def frozen(v): return v >= FB
def ttype(v): return v - FB if v >= FB else (v - HB if v >= HB else v)
def ctype(v): return v - FB if v >= FB else v   # hidden keeps its own code (blocked)


def blocked(st, v): return hidden(v) or (st.get('ice_conn', False) and frozen(v))


def dec(col):
    j, _, b = col['column'].partition('|')
    beads = []
    for x in (b.split(',') if b else []):
        if x.startswith('?'): beads.append(HB + int(x[1:]))
        elif x.startswith('i'): beads.append(FB + int(x[1:]))
        else: beads.append(int(x))
    lock = None
    if col.get('columnType') == 'unlock':
        info = col['columnInfo']
        lock = (info.get('condition'), info.get('typeId', -1), info.get('count', 0))
    if j == 'x': return ('x', -2, beads, lock)
    return ('j', -1 if j == '-' else int(j), beads, lock)


class Level:
    def __init__(s, raw):
        s.cap = raw['capacity']; s.target = raw['targetCups']
        s.init = [dec(c) for c in raw['initial']]
        inc = [dec(c) for c in raw['incoming']]
        while len(inc) < s.target - 1: inc.append(('x', -2, [], None))
        s.inc = inc
        s.sun = raw.get('sunlight', {}).get('typeId', -1) if raw.get('sunlight') else -1
        s.ice_conn = raw.get('iceMode') == 'blockConnection'
        s.frozen_pots = set(raw.get('frozenPots', []))
        s.late_park = sum(1 for e in inc if e[0] == 'j' and e[1] == -1)

    def state(s):
        cols = [list(c[2]) for c in s.init]
        jars = [c[1] for c in s.init]
        locks = [c[3] for c in s.init]
        st = dict(cols=cols, jars=jars, caps=[s.cap] * len(cols), gone=[False] * len(cols), locks=locks, done=0, cups=[],
                  ice_conn=s.ice_conn, fp=[i in s.frozen_pots for i in range(len(cols))])
        reveal(st)
        return st


def reveal(st):
    for c in st['cols']:
        if c and hidden(c[-1]): c[-1] = ttype(c[-1])


def move_k(st, src, j, dst):
    if src == dst: return 0
    if st['locks'][src] or st['locks'][dst]: return 0
    sc, dc = st['cols'][src], st['cols'][dst]
    k = len(sc) - j
    if j < 0 or k <= 0: return 0
    if len(dc) + k > st['caps'][dst]: return 0
    if not dc: return k
    a, b = sc[j], dc[-1]
    if blocked(st, a) or blocked(st, b): return 0
    return k if ctype(a) == ctype(b) else 0


def moves(st):
    """Mirror of useful_moves (non-root-swap)."""
    cols, caps, locks = st['cols'], st['caps'], st['locks']
    n = len(cols); out = []
    room = [0 if locks[d] else caps[d] - len(cols[d]) for d in range(n)]
    need = [-1 if not cols[d] else (-2 if blocked(st, cols[d][-1]) else ctype(cols[d][-1])) for d in range(n)]
    for i in range(n):
        if locks[i]: continue
        b = cols[i]; sz = len(b)
        if any(hidden(v) or frozen(v) for v in b):
            for j in range(sz):
                for d in range(n):
                    if move_k(st, i, j, d): out.append((i, j, d))
            continue
        s = 0
        while s < sz:
            head = b[s]; e = s
            while e + 1 < sz and b[e + 1] == head: e += 1
            kmin = sz - e
            for d in range(n):
                if d == i or kmin > room[d]: continue
                nd = need[d]
                if nd != -1 and (blocked(st, head) or nd != head): continue
                jb = max(s, sz - room[d])
                out.append((i, jb, d))
                if e != jb: out.append((i, e, d))
            s = e + 1
    return out


def ready(st, ci):
    if st['locks'][ci] or st['fp'][ci]: return False
    jar = st['jars'][ci]
    if jar < 0: return False
    col = st['cols'][ci]; cap = st['caps'][ci]
    if cap <= 0 or len(col) != cap: return False
    return all(v == jar for v in col)


def place(st, beads, cleared):
    n = len(st['cols']); order = [cleared] + [i for i in range(n) if i != cleared]
    for t in beads:
        for ci in order:
            if st['locks'][ci]: continue
            col = st['cols'][ci]
            if len(col) >= st['caps'][ci]: continue
            col.append(t); break
        else:
            break


def deposit(st, lv):
    guard = 0; fired = 0; again = True
    while again and guard < 40:
        guard += 1; again = False
        for ci in range(len(st['cols'])):
            if not ready(st, ci): continue
            fruit = st['jars'][ci]; k = st['done']
            sun = lv.sun >= 0 and fruit == lv.sun
            st['cols'][ci].clear()
            if sun:
                st['fp'] = [False] * len(st['fp'])
                for col in st['cols']:
                    for i, v in enumerate(col):
                        if frozen(v): col[i] = ttype(v)
            st['done'] = k + 1; st['cups'].append(fruit)
            kind, jar, beads, lock = lv.inc[k] if k < len(lv.inc) else ('x', -2, [], None)
            if kind == 'j' and jar >= 0:
                st['jars'][ci] = jar; st['caps'][ci] = lv.cap
            elif kind == 'j':
                st['jars'][ci] = -1; st['caps'][ci] = lv.cap
            else:
                st['jars'][ci] = -1; st['caps'][ci] = 0; st['gone'][ci] = True
            if beads: place(st, beads, ci)
            st['locks'][ci] = lock if not st['gone'][ci] else None
            fired += 1; again = True
    return fired


def unlock_pass(st):
    for ci, lk in enumerate(st['locks']):
        if not lk: continue
        cond, tid, cnt = lk
        if cond == 'collect_count': ok = st['done'] >= cnt
        else: ok = sum(1 for c in st['cups'] if c == tid) >= cnt
        if ok: st['locks'][ci] = None


def apply(st, lv, mv):
    src, j, dst = mv
    sc, dc = st['cols'][src], st['cols'][dst]
    dc.extend(sc[j:]); del sc[j:]
    if deposit(st, lv): unlock_pass(st)
    reveal(st)


def won(st, lv): return st['done'] >= lv.target


def doomed(st, lv):
    """max cups still collectable (even caps) < cups left  (mirror of max_groups_left, uniform capacity)."""
    cnt = {}
    for col in st['cols']:
        for v in col: cnt[ttype(v)] = cnt.get(ttype(v), 0) + 1
    for k in range(st['done'], len(lv.inc)):
        for v in lv.inc[k][2]: cnt[ttype(v)] = cnt.get(ttype(v), 0) + 1
    g = sum(c // lv.cap for c in cnt.values())
    return g < lv.target - st['done']


def clone(st):
    return dict(cols=[list(c) for c in st['cols']], jars=list(st['jars']), caps=list(st['caps']), gone=list(st['gone']),
                locks=list(st['locks']), done=st['done'], cups=list(st['cups']),
                ice_conn=st['ice_conn'], fp=list(st['fp']))


def key(st):
    return (tuple(tuple(c) for c in st['cols']), tuple(st['jars']), tuple(st['locks']), st['done'],
            tuple(sorted(st['cups'])) if any(st['locks']) else 0, tuple(st['caps']), tuple(st['fp']))


def free_slots(st):
    return sum(st['caps'][i] - len(c) for i, c in enumerate(st['cols']) if not st['locks'][i])


# ---------- bot ----------
def bot_play(lv, rng, max_moves=400, mode='greedy', trace=None):
    """Greedy-random player WITHOUT knowledge of hidden types (it only uses what is visible).
    Priority: complete a cup > merge onto same type > move to empty > anything. Random within tier."""
    st = lv.state(); nm = 0; seen = {}
    while nm < max_moves:
        if trace is not None: trace.append((st['done'], free_slots(st), st))   # st is live: last entry = final state
        if won(st, lv): return True, nm
        ms = moves(st)
        if not ms: return False, nm
        if doomed(st, lv): return False, nm
        scored = []
        for m in ms:
            src, j, dst = m
            sc, dc = st['cols'][src], st['cols'][dst]
            k = len(sc) - j
            pre = 0
            if st['jars'][dst] >= 0 and sc[j] == st['jars'][dst] and len(dc) + k == st['caps'][dst] and all(v == st['jars'][dst] for v in dc) and all(v == sc[j] for v in sc[j:]):
                pre = 5                       # completes a cup
            elif dc and ctype(sc[j]) == ctype(dc[-1]):
                pre = 3 if (len(sc) == k) else 2   # merge (emptying source is better)
                if st['jars'][dst] >= 0 and dc[-1] == st['jars'][dst]: pre += 1
            elif not dc:
                pre = 1 if st['jars'][dst] < 0 or sc[j] == st['jars'][dst] else 0
                if len(sc) == k: pre -= 1     # moving a whole column into an empty one is pointless
            scored.append((pre, rng.random(), m))
        scored.sort(reverse=True)
        top = scored[0][0]
        # avoid immediate repetition of states
        cand = [x for x in scored if x[0] >= top - (0 if mode == 'greedy' else 1)]
        choice = None
        for _, _, m in cand:
            t = clone(st); apply(t, lv, m)
            kk = key(t)
            if seen.get(kk, 0) < 2: choice = m; break
        if choice is None: choice = cand[0][2]
        apply(st, lv, choice); nm += 1
        seen[key(st)] = seen.get(key(st), 0) + 1
    return won(st, lv), nm


# ---------- solver (best-first, full state, hidden revealed by truth as they appear) ----------
def h_cost(st, lv):
    left = lv.target - st['done']
    h = left * 3
    for ci, col in enumerate(st['cols']):
        jar = st['jars'][ci]
        if jar >= 0:
            bad = sum(1 for v in col if v != jar)
            h += bad
    return h


def solve(lv, node_cap=60000):
    st = lv.state()
    pq = [(h_cost(st, lv), 0, 0, st)]; seen = {key(st): 0}; cnt = 0; nodes = 0
    while pq and nodes < node_cap:
        f, g, _, s = heapq.heappop(pq); nodes += 1
        if won(s, lv): return dict(solved=True, moves=g, nodes=nodes)
        if doomed(s, lv): continue
        for m in moves(s):
            t = clone(s); apply(t, lv, m)
            kk = key(t); ng = g + 1
            if kk in seen and seen[kk] <= ng: continue
            seen[kk] = ng; cnt += 1
            heapq.heappush(pq, (ng * 0.5 + h_cost(t, lv), ng, cnt, t))   # weighted A*: finds a good, not necessarily optimal, line
    return dict(solved=False, moves=-1, nodes=nodes)
