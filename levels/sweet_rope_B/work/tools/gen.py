#!/usr/bin/env python3
"""Sinh một level Sweet Rope bản B từ khung Sort Streak + núm độ khó.

Núm:
  mix    : tỉ lệ hoa bị hoán đổi khỏi dây "nhà" (0 = gần như đã xếp, 1 = trộn đều). Núm chính.
  short  : số hoa thiếu ở các dây màu ban đầu (dồn sang dây trắng đầu). Nhiều hơn = dễ hơn.
  hidden : số hoa ẩn (chỉ từ màn 6).
  lock   : None | ("collect_type", count) | ("collect_count", count)
  extra_empty : thêm dây trống (chậu trắng rỗng) vào initial (làm dễ).
Sức chứa và số dây ban đầu lấy đúng khung Sort Streak.
"""
import random


def make_level(slot, cap, cups, cols, ntypes, mix, short, hidden, lock, rng, extra_empty=0,
               types_pref=None, need_single=False):
    cols = max(3, min(7, cols))
    if cols + extra_empty > 7:
        extra_empty = 7 - cols
    n_init_col = cols - 1                      # dây 0 là chậu trắng
    cups = max(cups, n_init_col + 1)
    # chọn loại hoa
    types = list(types_pref) if types_pref else rng.sample(range(10), ntypes)
    ntypes = len(types)
    ntypes = min(ntypes, cups)
    types = types[:ntypes]
    # gán chậu: mỗi loại >= 1 chậu, còn lại ngẫu nhiên
    pots = list(types)
    while len(pots) < cups:
        pots.append(rng.choice(types))
    from collections import Counter
    cnt = Counter(pots)
    if need_single and not any(v == 1 for v in cnt.values()):
        # ép một loại chỉ còn 1 chậu
        t = min(cnt, key=lambda k: cnt[k])
        while cnt[t] > 1:
            i = pots.index(t); others = [k for k in types if k != t]
            pots[i] = rng.choice(others); cnt = Counter(pots)
    rng.shuffle(pots)
    init_pots = pots[:n_init_col]
    inc_pots = pots[n_init_col:]
    # dây nhà
    short = max(0, min(short, cap, n_init_col))
    init_lens = [cap] * n_init_col
    for i in rng.sample(range(n_init_col), short):
        init_lens[i] -= 1
    ropes = []  # (pot, [flowers]) theo thứ tự: initial colored, white, incoming
    for p, L in zip(init_pots, init_lens):
        ropes.append([p, [p] * L])
    missing = []
    for p in init_pots:
        pass
    # hoa thiếu của dây ban đầu: lấy cùng loại chậu tương ứng, đặt vào dây trắng
    white = [p for p, L in zip(init_pots, init_lens) if L < cap]
    for p in inc_pots:
        ropes.append([p, [p] * cap])
    # các chỗ hoa (vị trí) để trộn: mọi hoa trong initial + incoming + dây trắng
    white_rope = [None, list(white)]
    allr = ropes + [white_rope]
    pos = [(ri, k) for ri, r in enumerate(allr) for k in range(len(r[1]))]
    nswap = int(round(mix * len(pos)))
    for _ in range(nswap):
        a, b = rng.sample(pos, 2)
        fa = allr[a[0]][1][a[1]]; fb = allr[b[0]][1][b[1]]
        allr[a[0]][1][a[1]] = fb; allr[b[0]][1][b[1]] = fa
    # hoa ẩn: không ở đuôi dây; không ở dây trắng ban đầu
    if slot < 6:
        hidden = 0
    hid_set = set()
    cand = [(ri, k) for ri, r in enumerate(ropes) for k in range(len(r[1]) - 1)]
    hidden = min(hidden, len(cand))
    for x in rng.sample(cand, hidden):
        hid_set.add(x)

    def colstr(ri, r):
        p = '-' if r[0] is None else str(r[0])
        fl = [('?' if (ri, k) in hid_set else '') + str(f) for k, f in enumerate(r[1])]
        return p + '|' + ','.join(fl)

    initial = [{"column": colstr(-1, white_rope), "columnType": "default", "columnInfo": {}}]
    for i in range(n_init_col):
        initial.append({"column": colstr(i, ropes[i]), "columnType": "default", "columnInfo": {}})
    for _ in range(extra_empty):
        initial.append({"column": "-|", "columnType": "default", "columnInfo": {}})
    incoming = [{"column": colstr(n_init_col + j, ropes[n_init_col + j]), "columnType": "default", "columnInfo": {}}
                for j in range(len(inc_pots))]
    # chèn 1 chậu trắng rỗng vào incoming
    incoming.insert(rng.randint(1, max(1, len(incoming) - 1)), {"column": "-|", "columnType": "default", "columnInfo": {}})
    while len(incoming) < cups - 1:
        incoming.append({"column": "x|", "columnType": "default", "columnInfo": {}})
    incoming = incoming[:max(cups - 1, len(incoming))]
    # khóa: 1 dây màu ban đầu (không phải dây trắng)
    if lock and n_init_col >= 3:
        cond, count = lock
        li = 1 + rng.randrange(n_init_col)
        info = {"condition": cond, "count": int(count)}
        if cond == "collect_type":
            lt = int(initial[li]["column"].split('|')[0])
            others = [p for p in set(pots) if p != lt]
            t = rng.choice(others)
            info["typeId"] = t
            info["count"] = min(int(count), Counter(pots)[t])
        initial[li]["columnType"] = "unlock"
        initial[li]["columnInfo"] = info
    return {"id": slot, "capacity": cap, "targetCups": cups, "initial": initial, "incoming": incoming}


if __name__ == "__main__":
    import json
    print(json.dumps(make_level(30, 5, 11, 7, 9, 0.3, 2, 3, ("collect_count", 2), random.Random(1)), indent=1))
