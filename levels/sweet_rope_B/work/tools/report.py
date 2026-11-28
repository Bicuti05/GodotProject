#!/usr/bin/env python3
"""Báo cáo tổng hợp A/B: độ khó dự kiến vs thực tế, tỉ lệ thắng + số bước của bot, bố cục so Sort Streak, bonus, tag.
report.py in.json "ge_*.json" scores.csv out_prefix"""
import json, csv, glob, sys, collections, statistics as st
INP, GE, SC, OUT = sys.argv[1:5]
R = 'levels/sweet_rope_B'
lv = {x['uid']: x['raw'] for x in json.load(open(INP))}
ge = {x['uid']: x for f in glob.glob(GE) for x in json.load(open(f))}
sc = {r['uid']: r for r in csv.DictReader(open(SC))}
TB = list(csv.DictReader(open(f'{R}/docs/targets_B.csv', encoding='utf-8-sig')))
TA = list(csv.DictReader(open('levels/sweet_rope_A/work/targets_A.csv', encoding='utf-8-sig')))
TAm = {int(r['man']): float(r['diem_muc_tieu']) for r in csv.DictReader(open('levels/sweet_rope_A/report.csv', encoding='utf-8-sig'))}
CFG = ['eps0.3', 'eps0.45', 'eps0.6', 'softmaxT4']


def stat(raw):
    pots = collections.Counter(); types = set(); hid = 0; locks = 0; nfl = 0
    for c in raw['initial'] + raw['incoming']:
        p, _, b = c['column'].partition('|'); fl = [t for t in b.split(',') if t]
        if p not in ('-', 'x', ''): pots[int(p)] += 1; types.add(int(p))
        for t in fl: hid += t.startswith('?'); types.add(int(t.lstrip('?i'))); nfl += 1
        if c.get('columnType') == 'unlock': locks += 1
    single = sorted(t for t, v in pots.items() if v == 1)
    return dict(cap=int(raw['capacity']), cols=len(raw['initial']), tgt=int(raw['targetCups']), types=len(types), hidden=hid,
                locks=locks, inc_len=len(raw['incoming']), single=single, flowers=nfl)


def bot(uid):
    g = ge[uid]; w = []; s = []
    for c in g['cfg']:
        w.append(sum(x['win'] for x in c['seeds']) / len(c['seeds']))
        ws = [x['wsteps'] for x in c['seeds'] if x['wsteps'] > 0]; s.append(sum(ws) / len(ws) if ws else None)
    return w, s


rows = []
for r in TB:
    u = f"B|{r['slot']}|{r['group']}"
    for b in r['group'].split('+'):
        rows.append(dict(ban='B', bo=b, slot=int(r['slot']), uid=u, t=float(r['muc_tieu']), loai=r['loai'], db=r['dac_biet'], k=r))
rows.append(dict(ban='A', bo='A', slot=1, uid='A|001', t=TAm[1], loai='Normal', db='huong_dan', k=None))
for r in TA:
    rows.append(dict(ban='A', bo='A', slot=int(r['slot']), uid=f"A|{int(r['slot']):03d}", t=float(r['muc_tieu']),
                     loai=r['loai'], db=r['dac_biet'], k=r))
EFF = lambda t: t if t <= 70 else max(55.0, t - 18)  # bot chấm thấp ~18 ở vùng trên 70
for x in rows:
    x['tb'] = EFF(x['t'])
    x['d'] = float(sc[x['uid']]['diem_lw']); x['lw'] = float(sc[x['uid']]['lw']); x['w'], x['s'] = bot(x['uid']); x['st'] = stat(lv[x['uid']])
# chi tiết
with open(OUT + '_chi_tiet.csv', 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['ban', 'bo', 'man', 'loai', 'dac_biet', 'muc_tieu', 'muc_tieu_bot', 'diem_do', 'lech', 'lw'] + [f'win_{c}' for c in CFG] + [f'buoc_{c}' for c in CFG] +
               ['cap', 'cap_SS', 'so_day', 'so_day_SS', 'so_coc', 'so_coc_SS', 'so_mau', 'so_mau_SS', 'hoa_an', 'hoa_an_SS', 'khoa', 'khoa_SS', 'mau_1_chau'])
    for x in rows:
        k = x['k'] or {}
        g = lambda a: k.get(a, '')
        w.writerow([x['ban'], x['bo'], x['slot'], x['loai'], x['db'], x['t'], round(x['tb'], 1), x['d'], round(x['d'] - x['tb'], 1), x['lw']] +
                   [round(v, 3) for v in x['w']] + [round(v, 1) if v else '' for v in x['s']] +
                   [x['st']['cap'], g('khung_sort_streak_cap'), x['st']['cols'], g('khung_cols'), x['st']['tgt'], g('khung_tgt'),
                    x['st']['types'], g('khung_types_all'), x['st']['hidden'], g('khung_hidden'), x['st']['locks'], g('khung_locks'),
                    ' '.join(map(str, x['st']['single']))])
L = []
P = lambda v: f'{v:.1f}'
sets = ['A', 'default', 'lv2', 'lv3', 'lv4', 'lv5']
L.append('## 1. Độ khó dự kiến (mục tiêu) và thực tế (đo bằng bot, `diem_lw`)\n')
L.append('Lệch tính so với mục tiêu quy về thang bot: bằng mục tiêu nếu ≤ 70; trên 70 thì lấy mục tiêu − 18 (không dưới 55), vì bot chấm thấp khoảng 18 điểm ở vùng này.\n')
L.append('| Bộ | Số màn | Mục tiêu TB | Đo TB | Lệch TB (có dấu) | Sai số TB | ≤ 5 | 5–10 | > 10 |')
L.append('|---|---|---|---|---|---|---|---|---|')
for s in sets:
    X = [x for x in rows if x['bo'] == s]; e = [x['d'] - x['tb'] for x in X]
    L.append(f"| {s} | {len(X)} | {P(st.mean(x['t'] for x in X))} | {P(st.mean(x['d'] for x in X))} | {st.mean(e):+.1f} | {P(st.mean(map(abs, e)))} | "
             f"{sum(abs(v) <= 5 for v in e)} | {sum(5 < abs(v) <= 10 for v in e)} | {sum(abs(v) > 10 for v in e)} |")
L.append('\nTheo chặng 25 màn (mục tiêu → đo):\n')
L.append('| Màn | ' + ' | '.join(sets) + ' |'); L.append('|---' * (len(sets) + 1) + '|')
for a in range(1, 201, 25):
    cells = []
    for s in sets:
        X = [x for x in rows if x['bo'] == s and a <= x['slot'] < a + 25]
        cells.append(f"{P(st.mean(x['t'] for x in X))} → {P(st.mean(x['d'] for x in X))}" if X else '')
    L.append(f'| {a}–{a + 24} | ' + ' | '.join(cells) + ' |')
L.append('\n## 2. Bot: tỉ lệ thắng và số bước khi thắng (playtime)\n')
L.append('Bốn cấu hình bot greedy có nhiễu, mỗi cấu hình 2 seed × 30 ván. Playtime ước lượng = số bước TB × 3 giây/bước (giả định).\n')
L.append('| Bộ | ' + ' | '.join(f'Thắng {c}' for c in CFG) + ' | Thắng TB | Số bước TB | Playtime ước lượng |')
L.append('|---' * (len(CFG) + 4) + '|')
for s in sets:
    X = [x for x in rows if x['bo'] == s]
    wc = [st.mean(x['w'][i] for x in X) * 100 for i in range(4)]
    ss = [v for x in X for v in x['s'] if v]
    L.append(f"| {s} | " + ' | '.join(f'{v:.0f}%' for v in wc) + f" | {st.mean(wc):.0f}% | {st.mean(ss):.0f} | {st.mean(ss) * 3 / 60:.1f} phút |")
L.append('\nTheo chặng (thắng TB % / số bước TB):\n')
L.append('| Màn | ' + ' | '.join(sets) + ' |'); L.append('|---' * (len(sets) + 1) + '|')
for a in range(1, 201, 25):
    cells = []
    for s in sets:
        X = [x for x in rows if x['bo'] == s and a <= x['slot'] < a + 25]
        if not X: cells.append(''); continue
        ss = [v for x in X for v in x['s'] if v]
        cells.append(f"{st.mean(st.mean(x['w']) for x in X) * 100:.0f}% / {st.mean(ss) if ss else 0:.0f}")
    L.append(f'| {a}–{a + 24} | ' + ' | '.join(cells) + ' |')
L.append('\n## 3. Bố cục: level mới so với Sort Streak cùng màn, cùng bộ (TB mới / TB Sort Streak, % màn khớp đúng)\n')
F = [('cap', 'khung_sort_streak_cap', 'Sức chứa'), ('cols', 'khung_cols', 'Số dây đầu'), ('tgt', 'khung_tgt', 'Số cốc'),
     ('types', 'khung_types_all', 'Số màu'), ('hidden', 'khung_hidden', 'Hoa ẩn'), ('locks', 'khung_locks', 'Dây khóa'), ('inc_len', 'khung_inc_len', 'Độ dài hàng chờ')]
L.append('| Bộ | ' + ' | '.join(f[2] for f in F) + ' |'); L.append('|---' * (len(F) + 1) + '|')
for s in sets:
    X = [x for x in rows if x['bo'] == s and x['k']]
    cells = []
    for a, b, _ in F:
        n = st.mean(x['st'][a] for x in X); o = st.mean(float(x['k'][b]) for x in X); m = sum(x['st'][a] == int(x['k'][b]) for x in X) / len(X) * 100
        cells.append(f'{n:.1f} / {o:.1f} ({m:.0f}%)')
    L.append(f'| {s} | ' + ' | '.join(cells) + ' |')
L.append('\n## 4. Bonus\n')
for s in sets:
    X = [x for x in rows if x['bo'] == s]
    req = [x for x in X if x['slot'] >= 13 and (x['slot'] - 13) % 10 == 0]
    bad = [x['slot'] for x in req if not x['st']['single']]
    other = [x for x in X if x['st']['single'] and x not in req]
    L.append(f"- **{s}**: {len(req)} màn bonus cố định, {len(req) - len(bad)} đạt luật (có màu chỉ 1 chậu)"
             + (f", **không đạt: {bad}**" if bad else '') + f". Ngoài vị trí bonus còn **{len(other)} màn** cũng đủ điều kiện bonus.")
L.append('\nChi tiết màn ngoài vị trí bonus nhưng đủ điều kiện (màu chỉ có 1 chậu): xem cột `mau_1_chau` trong file chi tiết.\n')
L.append('## 5. Tag đặc biệt\n')
L.append('| Bộ | Hướng dẫn | Hard | Bonus | Challenge | Endless |'); L.append('|---|---|---|---|---|---|')
for s in sets:
    X = [x for x in rows if x['bo'] == s]
    c = collections.Counter(x['db'] for x in X)
    L.append(f"| {s} | {c.get('huong_dan', 0)} | {sum(x['loai'] == 'Hard' for x in X)} | {c.get('bonus', 0)} | {c.get('challenge', 0)} | {c.get('endless', 0)} |")
open(OUT + '.md', 'w').write('\n'.join(L) + '\n')
print('\n'.join(L))
# danh sách bonus tiềm năng
with open(OUT + '_bonus_tiem_nang.csv', 'w', newline='') as f:
    w = csv.writer(f); w.writerow(['bo', 'man', 'mau_chi_1_chau', 'ly_do'])
    for x in rows:
        if x['st']['single'] and not (x['slot'] >= 13 and (x['slot'] - 13) % 10 == 0):
            w.writerow([x['bo'], x['slot'], ' '.join(map(str, x['st']['single'])),
                        f"màu {', '.join(map(str, x['st']['single']))} chỉ có 1 chậu trên {x['st']['tgt']} cốc"])
