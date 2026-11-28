#!/usr/bin/env python3
"""Sửa level vi phạm 2 luật (bám Sort Streak):
  1. Không dây nào (initial hoặc mục incoming) đầy đúng sức chứa và toàn hoa thường cùng màu với chậu (giao ngay khi vào).
  2. Trên mỗi dây, tối đa 3 bông hoa thường cùng màu liền nhau (hoa ẩn không tính và cắt chuỗi).
Cách sửa: đổi loại hoa giữa hai vị trí (giữ nguyên trạng thái ẩn theo vị trí, số hoa mỗi màu, chậu, dây, khóa),
tìm kiếm cục bộ tới khi hết vi phạm, càng ít lần đổi càng tốt. Chỉ đổi trong cùng vùng (bàn chơi với bàn chơi,
hàng chờ với hàng chờ) để số hoa mỗi màu trên bàn không đổi.
Dùng như module: violations(raw), repair(raw, rng) -> raw mới hoặc None."""
import copy, random


def _ropes(raw):
    """Danh sách (part, idx, pot, items[[type, hidden]]) cho mọi dây có hoa."""
    out = []
    for part in ('initial', 'incoming'):
        for i, c in enumerate(raw[part]):
            p, _, f = c['column'].partition('|')
            if p == 'x': continue
            items = [[int(t.lstrip('?')), t.startswith('?')] for t in f.split(',') if t]
            out.append((part, i, p, items))
    return out


def _rope_viol(pot, items, cap):
    v = 0
    if pot not in ('-', 'x') and len(items) == cap and all((not h) and t == int(pot) for t, h in items):
        v += 3
    run, prev = 0, None
    for t, h in items:
        if h: run, prev = 0, None; continue
        run = run + 1 if t == prev else 1; prev = t
        if run >= 4: v += 1
    return v


def violations(raw):
    cap = int(raw['capacity'])
    return sum(_rope_viol(p, it, cap) for _, _, p, it in _ropes(raw))


def _write(raw, ropes):
    for part, i, p, items in ropes:
        c = raw[part][i]
        c['column'] = p + '|' + ','.join(('?' if h else '') + str(t) for t, h in items)


def repair(raw, rng, max_iter=4000):
    raw = copy.deepcopy(raw); cap = int(raw['capacity'])
    ropes = _ropes(raw)
    pos = [(ri, k) for ri, r in enumerate(ropes) for k in range(len(r[3]))]
    pos_by = {z: [(ri, k) for ri, k in pos if ropes[ri][0] == z] for z in ('initial', 'incoming')}
    rv = [_rope_viol(r[2], r[3], cap) for r in ropes]
    total = sum(rv)
    for _ in range(max_iter):
        if total == 0: break
        bad = [ri for ri, v in enumerate(rv) if v > 0]
        ri = rng.choice(bad); items = ropes[ri][3]
        k = rng.randrange(len(items))
        zone = ropes[ri][0]  # chỉ đổi trong cùng vùng: bàn chơi (initial) hoặc hàng chờ (incoming)
        rj, kj = rng.choice(pos_by[zone])
        if rj == ri and kj == k: continue
        a, b = items[k], ropes[rj][3][kj]
        if a[0] == b[0]: continue
        a[0], b[0] = b[0], a[0]
        n1 = _rope_viol(ropes[ri][2], ropes[ri][3], cap); n2 = _rope_viol(ropes[rj][2], ropes[rj][3], cap) if rj != ri else n1
        delta = (n1 - rv[ri]) + ((n2 - rv[rj]) if rj != ri else 0)
        if delta <= 0:
            total += delta; rv[ri] = n1; rv[rj] = n2
        else:
            a[0], b[0] = b[0], a[0]
    if total: return None
    _write(raw, ropes)
    return raw
