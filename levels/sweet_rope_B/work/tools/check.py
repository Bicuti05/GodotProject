#!/usr/bin/env python3
"""Kiểm + chọn phương án cho từng nhóm, chép vào final/, ghi báo cáo.
Dùng: check.py in.json "v_*.json" scores.csv a b out_prefix
(out_prefix vd levels/sweet_rope_B/reports/2026-11-27_kiem_man_26-50)"""
import json, csv, glob, sys, os, collections
INP, VG, SC, A, B, OUT = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4]), int(sys.argv[5]), sys.argv[6]
R = 'levels/sweet_rope_B'
items = json.load(open(INP))
val = {x['uid']: x for f in glob.glob(VG) for x in json.load(open(f))}
sc = {r['uid']: r for r in csv.DictReader(open(SC))}
tg = [r for r in csv.DictReader(open(os.environ.get('TARGETS', f'{R}/docs/targets_B.csv'), encoding='utf-8-sig')) if A <= int(r['slot']) <= B]


def stat(raw):
    pots = collections.Counter(); types = set(); hid = 0; tl = cl = 0; mx = 0
    for c in raw['initial'] + raw['incoming']:
        p, _, b = c['column'].partition('|'); fl = [t for t in b.split(',') if t]
        if p not in ('-', 'x', ''): pots[p] += 1; types.add(int(p))
        for t in fl: hid += t.startswith('?'); types.add(int(t.lstrip('?i')))
        if c.get('columnType') == 'unlock':
            ci = c['columnInfo']; mx = max(mx, int(ci.get('count', 0)))
            if ci.get('condition') == 'collect_type': tl += 1
            else: cl += 1
    return dict(types=len(types), hidden=hid, tl=tl, cl=cl, cnt=mx, one_pot=any(v == 1 for v in pots.values()), cap=int(raw['capacity']))


def problems(raw, r, uid):
    s = int(r['slot']); st = stat(raw); p = []
    v = val.get(uid, {})
    if not v.get('valid'): p.append('khong_hop_le')
    sol = v.get('solvable')
    lw = float(sc[uid]['lw']) if uid in sc else 0
    if sol == 'UNWINNABLE' or (sol != 'WINNABLE' and lw <= 0): p.append('chua_giai_duoc')
    if st['hidden'] and s < 6: p.append('hoa_an_som')
    if st['tl'] and s < 11: p.append('khoa_mau_som')
    if st['cl'] and s < 21: p.append('khoa_so_lan_som')
    if st['tl'] + st['cl'] > max(1, int(r['khung_locks'])): p.append('qua_nhieu_khoa')
    if s >= 13 and (s - 13) % 10 == 0 and not st['one_pot']: p.append('thieu_bonus')
    if s >= 3 and not 8 <= st['types'] <= 10: p.append('so_mau')
    if st['cap'] != int(r['khung_sort_streak_cap']): p.append('suc_chua_khac_SS')
    return p, st, sol, lw


by = collections.defaultdict(list)
for x in items:
    by[x['uid'].rsplit('_', 1)[0]].append(x)
rows = []
for r in tg:
    base = r['file'][:-5]; t = float(r['muc_tieu']); best = None; off = None
    if base not in by: continue
    for x in by.get(base, []):
        if x['uid'] not in sc: continue
        p, st, sol, lw = problems(x['raw'], r, x['uid'])
        d = float(sc[x['uid']]['diem_lw'])
        if x['uid'].endswith('_OFF'): off = d
        if p: continue
        if best is None or abs(d - t) < abs(best[1] - t): best = (x, d, st, sol, lw)
    row = dict(man=r['slot'], nhom=r['group'], muc_tieu=t, so_phuong_an=len(by.get(base, [])))
    if best:
        x, d, st, sol, lw = best
        raw = dict(x['raw']); raw['id'] = int(r['slot'])
        if os.environ.get('FINAL_A'):
            json.dump(raw, open(f'{os.environ["FINAL_A"]}/level_{int(r["slot"]):03d}.json', 'w'), indent=2)
        else:
          for b in r['group'].split('+'):
            os.makedirs(f'{R}/final/{b}', exist_ok=True)
            json.dump(raw, open(f'{R}/final/{b}/level_{int(r["slot"]):03d}.json', 'w'), indent=2)
        row.update(chon=x['uid'], la_ban_chinh_thuc=x['uid'].endswith('_OFF'), diem_do_lai=d, lech=round(d - t, 1),
                   diem_ban_chinh_thuc=off, giai_duoc=sol if sol == 'WINNABLE' else 'WINNABLE (bot thang)', lw=lw,
                   suc_chua=st['cap'], so_mau=st['types'], hoa_an=st['hidden'], day_khoa=st['tl'] + st['cl'])
    else:
        row.update(chon='', lech='', giai_duoc='KHONG CO PHUONG AN DAT')
    rows.append(row)
keys = ['man', 'nhom', 'muc_tieu', 'so_phuong_an', 'chon', 'la_ban_chinh_thuc', 'diem_do_lai', 'lech', 'diem_ban_chinh_thuc',
        'giai_duoc', 'lw', 'suc_chua', 'so_mau', 'hoa_an', 'day_khoa']
w = csv.DictWriter(open(OUT + '.csv', 'w', newline=''), fieldnames=keys); w.writeheader(); [w.writerow(x) for x in rows]
ok = [x for x in rows if x['chon']]; e = [abs(x['lech']) for x in ok]
bad = sorted([x for x in ok if abs(x['lech']) > 10], key=lambda x: -abs(x['lech']))
miss = [x for x in rows if not x['chon']]
md = [f'# Kiểm bộ B, màn {A}–{B}', '',
      'Chấm bằng `tools/score.py` (cột `diem_lw`). Luật lọc: hợp lệ, giải được (solver 60 000 nút, hoặc bot greedy thắng ít nhất 1 ván), '
      'đúng mốc cơ chế, bonus, 8–10 loại hoa, ≤ 1 dây khóa, **sức chứa đúng bằng Sort Streak cùng màn cùng bộ**. '
      'Chọn phương án lệch ít nhất, chép vào `final/<bộ>/level_###.json`.', '',
      f'- {len(rows)} nhóm, {len(ok)} nhóm có phương án đạt luật. Sai số TB tuyệt đối {sum(e)/max(1,len(e)):.1f}; '
      f'{sum(v<=5 for v in e)} nhóm lệch ≤ 5, {sum(5<v<=10 for v in e)} nhóm 5–10, {len(bad)} nhóm > 10.',
      f'- {sum(bool(x["la_ban_chinh_thuc"]) for x in ok)} nhóm dùng bản chính thức, {sum(not x["la_ban_chinh_thuc"] for x in ok)} nhóm dùng candidates.', '']
if miss:
    md += ['## Không có phương án đạt luật (cần sinh lại)', ''] + [f'- Màn {x["man"]} `{x["nhom"]}`' for x in miss] + ['']
md += ['## Cần sinh lại (lệch > 10)', '', '| Màn | Nhóm | Mục tiêu | Điểm đo lại | Lệch | Hướng sửa |', '|---|---|---|---|---|---|']
md += [f'| {x["man"]} | {x["nhom"]} | {x["muc_tieu"]} | {x["diem_do_lai"]} | {x["lech"]:+} | {"làm dễ hơn" if x["lech"]>0 else "làm khó hơn"} |' for x in bad]
open(OUT + '.md', 'w').write('\n'.join(md) + '\n')
print('\n'.join(md[4:6]), '| thiếu', len(miss), '| >10:', len(bad))
