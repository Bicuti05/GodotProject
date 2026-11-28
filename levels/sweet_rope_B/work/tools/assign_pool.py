#!/usr/bin/env python3
"""Phân phối kho level đã chấm vào các ô (màn, bộ) theo điểm mục tiêu (Hungarian), mỗi level dùng một lần.
Dùng: assign_pool.py POOL_DIRS... --out OUT_DIR [--apply] [--tol 5]
  POOL_DIRS: các thư mục chứa file đầu vào ({gen,in,chk_in,full_in,miss}.json: [{uid, raw}]) và kết quả greedy_ext (ge_*.json).
Ô: bản A màn 10–200 và bản B mọi nhóm trừ màn đầu đã chốt dễ (A 2–9, B 2–5 và default 6–9 giữ nguyên).
Điều kiện ghép: đúng luật bàn chơi (repair.violations = 0), bot thắng ít nhất 1 ván, sức chứa bằng khung Sort Streak,
số dây lúc mở bằng khung (hoặc +1 dây trống), ≤ 14 cốc, 8–10 màu, mốc cơ chế (hoa ẩn ≥ 6, khóa màu ≥ 11, khóa số lần ≥ 21),
màn bonus có màu chỉ 1 chậu, ≤ 1 dây khóa.
Mục tiêu dùng để so: t nếu t ≤ 70, ngược lại max(55, t − 18) (bot chấm thấp ~18 ở vùng trên 70)."""
import json, csv, glob, os, sys, subprocess, collections
import numpy as np
from scipy.optimize import linear_sum_assignment
sys.path.insert(0, os.path.dirname(__file__))
import repair as RP
R = 'levels/sweet_rope_B'
args = sys.argv[1:]
out = args[args.index('--out') + 1]; apply_ = '--apply' in args
tol = float(args[args.index('--tol') + 1]) if '--tol' in args else 5.0
dirs = [a for a in args if not a.startswith('--') and a not in (out, str(tol))]
os.makedirs(out, exist_ok=True)
H = lambda r: json.dumps({k: r[k] for k in ('capacity', 'targetCups', 'initial', 'incoming')}, sort_keys=True)


def feats(raw):
    pots = collections.Counter(); types = set(); hid = 0; tl = cl = 0
    for c in raw['initial'] + raw['incoming']:
        p, _, f = c['column'].partition('|'); fl = [x for x in f.split(',') if x]
        if p not in ('-', 'x', ''): pots[p] += 1; types.add(int(p))
        for t in fl: hid += t.startswith('?'); types.add(int(t.lstrip('?i')))
        if c.get('columnType') == 'unlock':
            if c['columnInfo'].get('condition') == 'collect_type': tl += 1
            else: cl += 1
    return dict(cap=int(raw['capacity']), cols=len(raw['initial']), cups=int(raw['targetCups']), types=len(types), hid=hid, tl=tl, cl=cl,
                single=any(v == 1 for v in pots.values()))


# kho
pool = {}
for d in dirs:
    raw = {}
    for f in ('gen.json', 'in.json', 'chk_in.json', 'full_in.json', 'miss.json', 'cur.json'):
        p = os.path.join(d, f)
        if os.path.exists(p):
            for x in json.load(open(p)): raw[x['uid']] = x['raw']
    gs = glob.glob(os.path.join(d, 'ge_*.json'))
    if not gs: continue
    sc = subprocess.run(['python3', f'{R}/tools/score.py', os.path.join(d, 'ge_*.json')], capture_output=True, text=True).stdout
    for r in csv.DictReader(sc.splitlines()):
        u = r['uid']
        if u not in raw or float(r['lw']) <= 0: continue
        lv = raw[u]
        if RP.violations(lv): continue
        pool[H(lv)] = dict(raw=lv, d=float(r['diem_lw']), lw=float(r['lw']), f=feats(lv), src=f'{os.path.basename(d.rstrip("/"))}:{u}')
# loại level đang dùng ở các màn đầu đã chốt (A 2–9, B 2–5, B default 6–9) để không dùng lại ở màn khác
fixed = set()
for n in range(2, 10): fixed.add(H(json.load(open(f'levels/sweet_rope_A/level_{n:03d}.json'))))
for r in csv.DictReader(open(f'{R}/docs/targets_B.csv', encoding='utf-8-sig')):
    s0 = int(r['slot'])
    if 2 <= s0 <= 5 or (r['group'] == 'default' and 6 <= s0 <= 9):
        fixed.add(H(json.load(open(f"{R}/final/{r['group'].split('+')[0]}/level_{s0:03d}.json"))))
pool = [v for k, v in pool.items() if k not in fixed]
print('kho', len(pool), 'level đúng luật, bot thắng được', collections.Counter(p['f']['cap'] for p in pool))

# ô
slots = []
ta = {int(r['man']): float(r['diem_muc_tieu']) for r in csv.DictReader(open('levels/sweet_rope_A/report.csv', encoding='utf-8-sig'))}
for r in csv.DictReader(open('levels/sweet_rope_A/work/targets_A.csv', encoding='utf-8-sig')):
    s = int(r['slot'])
    if s >= 10: slots.append(dict(key=f'A|{s}', ban='A', slot=s, t=ta[s], fr=r))
for r in csv.DictReader(open(f'{R}/docs/targets_B.csv', encoding='utf-8-sig')):
    s = int(r['slot'])
    if 2 <= s <= 5 or (r['group'] == 'default' and 6 <= s <= 9): continue
    slots.append(dict(key=f"B|{s}|{r['group']}", ban='B', slot=s, t=float(r['muc_tieu']), fr=r, group=r['group'], file=r['file']))
eff = lambda t: t if t <= 70 else max(55.0, t - 18)


def ok(sl, p):
    f = p['f']; fr = sl['fr']; s = sl['slot']
    if f['cap'] != int(fr['khung_sort_streak_cap']): return False
    if f['cols'] not in (int(fr['khung_cols']), int(fr['khung_cols']) + 1): return False
    if f['cups'] > 14 or not (8 <= f['types'] <= 10): return False
    if f['hid'] and s < 6: return False
    if f['tl'] and s < 11: return False
    if f['cl'] and s < 21: return False
    if f['tl'] + f['cl'] > 1: return False
    if s >= 13 and (s - 13) % 10 == 0 and not f['single']: return False
    return True


BIG = 1e6
C = np.full((len(slots), len(pool)), BIG)
for i, sl in enumerate(slots):
    te = eff(sl['t'])
    for j, p in enumerate(pool):
        if ok(sl, p): C[i, j] = abs(p['d'] - te)
ri, ci = linear_sum_assignment(C)
rows = []; miss = []
for i, j in zip(ri, ci):
    sl = slots[i]; c = C[i, j]; p = pool[j]
    good = c <= tol
    rows.append(dict(ban=sl['ban'], man=sl['slot'], nhom=sl.get('group', 'A'), muc_tieu=sl['t'], muc_tieu_so=round(eff(sl['t']), 1),
                     diem=p['d'] if c < BIG else '', lech=round(p['d'] - eff(sl['t']), 1) if c < BIG else '', dat=good, nguon=p['src'] if c < BIG else '',
                     cap=int(sl['fr']['khung_sort_streak_cap'])))
    if not good: miss.append(rows[-1])
    if apply_ and good:
        raw = dict(p['raw']); raw['id'] = sl['slot']
        if sl['ban'] == 'A':
            json.dump(raw, open(f"levels/sweet_rope_A/level_{sl['slot']:03d}.json", 'w'), indent=2)
        else:
            json.dump(raw, open(f"{R}/work/{sl['file']}", 'w'), indent=2)
            for b in sl['group'].split('+'): json.dump(raw, open(f"{R}/final/{b}/level_{sl['slot']:03d}.json", 'w'), indent=2)
w = csv.DictWriter(open(f'{out}/assign.csv', 'w', newline=''), fieldnames=list(rows[0])); w.writeheader(); [w.writerow(x) for x in rows]
json.dump(miss, open(f'{out}/miss.json', 'w'))
e = [abs(x['lech']) for x in rows if x['lech'] != '']
print('ô', len(slots), '| đạt ±%g:' % tol, sum(x['dat'] for x in rows), '| chưa đạt', len(miss), '| sai số TB (ô có level)', round(sum(e) / max(1, len(e)), 2))
by = collections.Counter((x['cap'], int(x['muc_tieu_so'] // 10 * 10)) for x in miss)
print('thiếu theo (sức chứa, dải điểm):', sorted(by.items()))
