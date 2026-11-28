#!/usr/bin/env python3
"""Bộ sinh level kiểu Sort Streak (thay gen.py):
- Bàn chơi không đầy: các dây màu lúc mở có khoảng fill*cap hoa; hoa dư nằm trong hàng chờ,
  kể cả các mục chậu trắng (Free) có hoa.
- Hoa xếp ngẫu nhiên, thiên về dây cùng màu chậu với xác suất `home`, rồi sửa theo luật (repair.py):
  không dây nào đầy và toàn màu chậu; tối đa 3 hoa thường cùng màu liền nhau.
Núm: fill (0.3–1.0, ít = dễ), home (0–0.8, nhiều = dễ), hidden, lock, extra_empty."""
from collections import Counter
import repair as RP


def make_level(slot, cap, cups, cols, ntypes, fill, home, hidden, lock, rng, extra_empty=0, types_pref=None, need_single=False):
    cols = max(3, min(7, cols)); extra_empty = max(0, min(extra_empty, 7 - cols))
    n_init = cols - 1
    cups = max(cups, n_init + 1)
    types = list(types_pref)[:ntypes] if types_pref else rng.sample(range(10), ntypes)
    pots = list(types)
    while len(pots) < cups: pots.append(rng.choice(types))
    if need_single and not any(v == 1 for v in Counter(pots).values()):
        cnt = Counter(pots); t = min(cnt, key=lambda k: cnt[k])
        while Counter(pots)[t] > 1:
            pots[pots.index(t)] = rng.choice([k for k in types if k != t])
    rng.shuffle(pots)
    init_pots, inc_pots = pots[:n_init], pots[n_init:]
    max_free = max(0, min(3, (cups - 1) - len(inc_pots) - 1))   # chừa 1 chỗ cho mục trắng rỗng
    init_len = [max(0, min(cap - 1, round(cap * fill + rng.uniform(-1, 1)))) for _ in init_pots]
    white_len = max(0, min(cap - 1, round(cap * fill * 0.5)))
    inc_len = [cap] * len(inc_pots)
    rest = cups * cap - sum(init_len) - white_len - sum(inc_len)
    free_len = []
    while rest > 0 and len(free_len) < max_free:
        k = min(cap, rest); free_len.append(k); rest -= k
    i = 0
    while rest > 0 and i < 5000:
        j = i % len(init_len)
        if init_len[j] < cap: init_len[j] += 1; rest -= 1
        i += 1
    if rest > 0: return None
    ropes = [(str(p), L) for p, L in zip(init_pots, init_len)] + [('-', white_len)] + [(str(p), L) for p, L in zip(inc_pots, inc_len)] + [('-', L) for L in free_len]
    bag = Counter()
    for p in pots: bag[p] += cap
    pool = [t for t, c in bag.items() for _ in range(c)]
    rng.shuffle(pool)
    content = [[] for _ in ropes]
    for ri in sorted(range(len(ropes)), key=lambda r: rng.random()):
        p, L = ropes[ri]
        for _ in range(L):
            pick = None
            if p != '-' and rng.random() < home:
                cand = [k for k, f in enumerate(pool) if f == int(p)]
                if cand: pick = rng.choice(cand)
            if pick is None: pick = rng.randrange(len(pool))
            content[ri].append(pool.pop(pick))
    # hoa ẩn: không ở đuôi dây, không ở dây trắng lúc mở
    hid = set()
    if slot >= 6 and hidden > 0:
        cand = [(ri, k) for ri, c in enumerate(content) for k in range(len(c) - 1) if ri != n_init]
        hid = set(rng.sample(cand, min(hidden, len(cand))))
    col = lambda ri: ropes[ri][0] + '|' + ','.join(('?' if (ri, k) in hid else '') + str(t) for k, t in enumerate(content[ri]))
    initial = [{'column': col(n_init), 'columnType': 'default', 'columnInfo': {}}]
    initial += [{'column': col(ri), 'columnType': 'default', 'columnInfo': {}} for ri in range(n_init)]
    initial += [{'column': '-|', 'columnType': 'default', 'columnInfo': {}} for _ in range(extra_empty)]
    inc_idx = list(range(n_init + 1, len(ropes)))
    rng.shuffle(inc_idx)
    incoming = [{'column': col(ri), 'columnType': 'default', 'columnInfo': {}} for ri in inc_idx]
    incoming.insert(rng.randint(1, max(1, len(incoming) - 1)), {'column': '-|', 'columnType': 'default', 'columnInfo': {}})
    while len(incoming) < cups - 1: incoming.append({'column': 'x|', 'columnType': 'default', 'columnInfo': {}})
    if len(incoming) > cups - 1: return None
    if lock and n_init >= 3:
        cond, count = lock; li = 1 + rng.randrange(n_init)
        info = {'condition': cond, 'count': int(count)}
        if cond == 'collect_type':
            lt = int(initial[li]['column'].split('|')[0])
            t = rng.choice([p for p in set(pots) if p != lt]); info['typeId'] = t; info['count'] = min(int(count), Counter(pots)[t])
        initial[li]['columnType'] = 'unlock'; initial[li]['columnInfo'] = info
    raw = {'id': slot, 'capacity': cap, 'targetCups': cups, 'initial': initial, 'incoming': incoming}
    return RP.repair(raw, rng)
