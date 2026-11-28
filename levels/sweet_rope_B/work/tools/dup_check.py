#!/usr/bin/env python3
"""Kiểm trùng lặp: so mỗi level mới với mọi level có sẵn trong project (Sort Streak, LevelDesigner, GD_Lazy, bản A cũ).
Độ giống = tỉ lệ vị trí (chậu + hoa, theo thứ tự dây initial rồi incoming) trùng nhau sau khi đổi tên màu tối ưu
(Hungarian trên ma trận đồng xuất hiện), chia cho số vị trí của level dài hơn. Chỉ so cặp cùng sức chứa.
Dùng: dup_check.py originals.json new.json out.csv   (mỗi file: [{uid, raw}])"""
import json, sys, csv
import numpy as np
from scipy.optimize import linear_sum_assignment


def seq(raw):
    s = []
    for part in ('initial', 'incoming'):
        for ri, c in enumerate(raw.get(part, [])):
            pot, _, fl = c['column'].partition('|')
            if pot in ('x', ''): continue
            s.append((part, ri, -1, 10 if pot == '-' else int(pot)))
            for k, t in enumerate([x for x in fl.split(',') if x]):
                s.append((part, ri, k, int(t.lstrip('?i'))))
    return s


def enc(raw):
    s = seq(raw); d = {p[:3]: p[3] for p in s}
    return d, len(s)


def sim(a, b):
    da, na = a; db, nb = b
    keys = da.keys() & db.keys()
    if not keys: return 0.0
    M = np.zeros((11, 11))
    for k in keys: M[da[k], db[k]] += 1
    M[10, :10] = 0; M[:10, 10] = 0  # chậu trắng chỉ ghép với chậu trắng
    r, c = linear_sum_assignment(-M)
    return float(M[r, c].sum()) / max(na, nb)


def grid(d):
    g = np.full(400, -1, dtype=np.int8)
    for (part, ri, k), t in d.items():
        i = (0 if part == 'initial' else 10) * 20 + ri * 20 + (k + 1) if part == 'initial' else 200 + ri * 10 + (k + 1)
        if 0 <= i < 400 and k < 9: g[i] = t
    return g


def onehot(G):
    H = np.zeros(G.shape + (11,), dtype=np.float32)
    m = G >= 0
    idx = np.nonzero(m)
    H[idx + (G[m].astype(int),)] = 1
    return H


def main():
    orig = json.load(open(sys.argv[1])); new = json.load(open(sys.argv[2]))
    by = {}
    for o in orig:
        try: by.setdefault(int(o['raw']['capacity']), []).append((o['uid'], enc(o['raw'])))
        except Exception: pass
    pre = {}
    for cap, L in by.items():
        G = np.stack([grid(e[0]) for _, e in L]); pre[cap] = (L, onehot(G), np.array([e[1] for _, e in L]))
    w = csv.writer(open(sys.argv[3], 'w', newline='')); w.writerow(['uid', 'sim_max', 'nearest'])
    for x in new:
        e = enc(x['raw']); best = (0.0, '')
        cap = int(x['raw']['capacity'])
        if cap in pre:
            L, H, N = pre[cap]
            h = onehot(grid(e[0])[None])[0]
            M = np.einsum('pa,npb->nab', h, H)
            M[:, 10, :10] = 0; M[:, :10, 10] = 0
            bound = M.max(axis=2).sum(axis=1) / np.maximum(N, e[1])
            for j in np.argsort(-bound)[:5]:
                r, c = linear_sum_assignment(-M[j])
                s = float(M[j][r, c].sum()) / max(N[j], e[1])
                if s > best[0]: best = (s, L[j][0])
        w.writerow([x['uid'], round(best[0], 3), best[1]])


if __name__ == '__main__':
    main()
