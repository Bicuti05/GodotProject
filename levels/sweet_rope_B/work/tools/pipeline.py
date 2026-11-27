#!/usr/bin/env python3
"""Sinh + kiểm + chấm + chọn một lô màn bản B.
Dùng (từ gốc repo): python3 levels/sweet_rope_B/work/tools/pipeline.py A B N TMPDIR
  A..B: dải màn; N: số ứng viên mỗi nhóm. Cần godot 4.6.1 trên PATH, các .gd trong .godot/
  (greedy_ext.gd, validate_big.gd: bản sao ở levels/sweet_rope_B/work/tools/).
Ghi: work/L*.json (bản tốt nhất), work/candidates/<file> (mọi ứng viên đã chấm),
     work/self_report.csv, work/assignment.csv, rồi check.py -> final/ + reports/.
"""
import json, csv, os, random, subprocess, sys, glob, math
sys.path.insert(0, os.path.dirname(__file__))
import gen
R = 'levels/sweet_rope_B'; W = f'{R}/work'
A, B, N, T = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
os.makedirs(T, exist_ok=True)
tg = [r for r in csv.DictReader(open(f'{R}/docs/targets_B.csv', encoding='utf-8-sig')) if A <= int(r['slot']) <= B]
# lô đặt lại (sinh lại) nếu có file REDO
redo = os.environ.get('REDO')
if redo: tg = [r for r in tg if r['file'] in set(redo.split(','))]


def godot(script, inp, outp, shards=4, to=7200):
    ps = [subprocess.Popen(['godot', '--headless', '--path', '.', '-s', f'res://.godot/{script}', '--', inp, f'{outp}_{i}.json', str(i), str(shards)],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) for i in range(shards)]
    for p in ps: p.wait(timeout=to)
    return [x for i in range(shards) for x in json.load(open(f'{outp}_{i}.json'))]


def knobs(t, k, n, rng):
    # độ khó tăng theo mix và giảm khi short lớn; trải đều quanh tâm ước lượng
    c = 0.04 + 0.22 * min(t, 85) / 85
    mix = max(0.0, min(0.32, c + (k / max(1, n - 1) - 0.5) * 0.16 + rng.uniform(-0.02, 0.02)))
    short = 3 if t < 15 else 2 if t < 35 else rng.choice([1, 2])
    return mix, short


items = []
gi = 0
for r in sorted(tg, key=lambda r: -int(r['slot'])):
    s = int(r['slot']); t = float(r['muc_tieu']); base = r['file'][:-5]
    rng = random.Random(hash((s, r['group'], 'B1')) & 0xffffffff)
    cap = int(r['khung_sort_streak_cap']); cups = max(8, min(14, int(r['khung_tgt'])))
    cols = int(r['khung_cols']); nt = max(8, min(10, int(r['khung_types_all'])))
    hid = int(r['khung_hidden']) if s >= 6 else 0
    bonus = s >= 13 and (s - 13) % 10 == 0
    for k in range(N):
        mix, short = knobs(t, k, N, rng)
        lock = None
        if int(r['khung_locks']) > 0 and s >= 11 and rng.random() < 0.7:
            cond = 'collect_count' if s >= 21 and rng.random() < 0.6 else 'collect_type'
            lock = (cond, rng.randint(1, 3 if cond == 'collect_count' else 2))
        drop = [(gi * 3 + j * 7) % 10 for j in range(10 - nt)]; gi += 1
        types = [x for x in range(10) if x not in drop]
        rng.shuffle(types)
        raw = gen.make_level(s, cap, cups, cols, nt, mix, short, hid + rng.randint(-1, 1) if hid else 0, lock, rng,
                             types_pref=types, need_single=bonus)
        items.append({'uid': f'{base}_g{k:02d}', 'raw': raw, 'knob': {'mix': round(mix, 3), 'short': short, 'lock': lock}})
json.dump(items, open(f'{T}/gen.json', 'w'))
print('generated', len(items), flush=True)
v = {x['uid']: x for x in godot('validate_big.gd', f'{T}/gen.json', f'{T}/v')}
keep = [x for x in items if v[x['uid']].get('valid') and v[x['uid']].get('solvable') != 'UNWINNABLE']
json.dump(keep, open(f'{T}/in.json', 'w'))
print('kept', len(keep), flush=True)
godot('greedy_ext.gd', f'{T}/in.json', f'{T}/ge')
out = subprocess.run(['python3', f'{R}/tools/score.py', f'{T}/ge_*.json'], capture_output=True, text=True).stdout
open(f'{T}/scores.csv', 'w').write(out)
sc = {x['uid']: x for x in csv.DictReader(open(f'{T}/scores.csv'))}
# ghi work/
os.makedirs(f'{W}/candidates', exist_ok=True)
sr = {(x['slot'], x['group']): x for x in csv.DictReader(open(f'{W}/self_report.csv'))} if os.path.exists(f'{W}/self_report.csv') else {}
asg = {(x['bo'], x['slot']): x for x in csv.DictReader(open(f'{W}/assignment.csv'))} if os.path.exists(f'{W}/assignment.csv') else {}
by = {}
for x in keep: by.setdefault(x['uid'].rsplit('_', 1)[0], []).append(x)
for r in tg:
    base = r['file'][:-5]; t = float(r['muc_tieu']); cs = [x for x in by.get(base, []) if x['uid'] in sc]
    if not cs: continue
    for x in cs:
        x['valid'] = True; x['solvable'] = v[x['uid']]['solvable']; x['lw'] = float(sc[x['uid']]['lw']); x['diem_lw'] = float(sc[x['uid']]['diem_lw'])
    ok = [x for x in cs if x['solvable'] == 'WINNABLE' or x['lw'] > 0] or cs
    best = min(ok, key=lambda x: abs(x['diem_lw'] - t))
    cp = f'{W}/candidates/{r["file"]}'
    old = json.load(open(cp)) if os.path.exists(cp) else []
    oldbest = None
    if os.path.exists(f'{W}/{r["file"]}') and (r['slot'], r['group']) in sr:
        try: oldbest = float(sr[(r['slot'], r['group'])].get('diem_lw') or sr[(r['slot'], r['group'])].get('diem_tu_uoc_luong'))
        except Exception: oldbest = None
    json.dump(old + cs, open(cp, 'w'))
    if oldbest is not None and abs(oldbest - t) <= abs(best['diem_lw'] - t):
        continue
    json.dump(best['raw'], open(f'{W}/{r["file"]}', 'w'), indent=2)
    sr[(r['slot'], r['group'])] = dict(slot=r['slot'], group=r['group'], file=r['file'], valid='true', solvable=best['solvable'],
                                       lw=best['lw'], diem_lw=best['diem_lw'], muc_tieu=t, lech=round(best['diem_lw'] - t, 2))
    for b in r['group'].split('+'): asg[(b, r['slot'])] = dict(bo=b, slot=r['slot'], file=r['file'])
keys = ['slot', 'group', 'file', 'valid', 'solvable', 'lw', 'diem_lw', 'muc_tieu', 'lech']
rows = sorted(sr.values(), key=lambda x: (int(x['slot']), x['group']))
with open(f'{W}/self_report.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=keys, extrasaction='ignore'); w.writeheader()
    for x in rows:
        if not x.get('diem_lw'): x['diem_lw'] = x.get('diem_tu_uoc_luong', '')
        w.writerow(x)
with open(f'{W}/assignment.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=['bo', 'slot', 'file']); w.writeheader()
    [w.writerow(x) for x in sorted(asg.values(), key=lambda x: (int(x['slot']), x['bo']))]
# đầu vào cho check.py: tất cả ứng viên đã chấm của lô này
json.dump([{'uid': x['uid'], 'raw': x['raw']} for x in keep if x['uid'] in sc], open(f'{T}/chk_in.json', 'w'))
json.dump([v[x['uid']] for x in keep], open(f'{T}/chk_v.json', 'w'))
print('done', flush=True)
