#!/usr/bin/env python3
"""Sửa các màn lệch xa mục tiêu (A và B) theo 2 bước: sàng nhanh nhiều ứng viên, chấm đầy đủ vài bản tốt nhất.
Dùng (từ gốc repo), chạy lần lượt từng bước (mỗi bước có thể chạy lại):
  refine.py plan  CHI_TIET.csv NGUONG TMP   -> TMP/plan.json (màn/nhóm có |lệch| > NGUONG)
  refine.py gen   TMP N                      -> sinh N ứng viên mỗi mục, kiểm giải được (validate_big.gd)
  refine.py screen TMP                       -> chấm nhanh (greedy_screen.gd: 2 bot × 1 seed × 30 ván)
  refine.py full  TMP K                      -> chấm đầy đủ K bản gần mục tiêu nhất (greedy_ext.gd)
  refine.py apply TMP                        -> thay level khi bản mới gần mục tiêu hơn; ghi TMP/apply.csv
Hiệu chỉnh mix -> điểm theo sức chứa (trung vị của 5 463 ứng viên đã chấm; độ lệch chuẩn ~30 nên cần nhiều ứng viên)."""
import json, csv, os, sys, random, subprocess, glob
sys.path.insert(0, os.path.dirname(__file__))
import gen
R = 'levels/sweet_rope_B'
CAL = {4: ([0, 2, 9, 20, 55, 74, 85, 100], [0.05, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20]),
       5: ([0, 6, 22, 48, 74, 86, 94, 100], [0.05, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20]),
       6: ([0, 3, 28, 53, 69, 94, 100], [0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16])}


def center(cap, t):
    X, Y = CAL.get(cap, CAL[5]); t = max(0, min(100, t))
    for i in range(1, len(X)):
        if t <= X[i]: return Y[i - 1] + (Y[i] - Y[i - 1]) * (t - X[i - 1]) / (X[i] - X[i - 1])
    return Y[-1]


def godot(script, inp, outp, shards=4):
    ps = [subprocess.Popen(['godot', '--headless', '--path', '.', '-s', f'res://.godot/{script}', '--', inp, f'{outp}_{i}.json', str(i), str(shards)],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) for i in range(shards)]
    for p in ps: p.wait()
    return [x for i in range(shards) for x in json.load(open(f'{outp}_{i}.json'))]


def score(pattern):
    out = subprocess.run(['python3', f'{R}/tools/score.py', pattern], capture_output=True, text=True).stdout
    return {r['uid']: r for r in csv.DictReader(out.splitlines())}


cmd, T = sys.argv[1], sys.argv[-1] if sys.argv[1] in ('plan',) else sys.argv[2]
if cmd == 'plan':
    src, thr, T = sys.argv[2], float(sys.argv[3]), sys.argv[4]; os.makedirs(T, exist_ok=True)
    tb = {(r['slot'], b): r for r in csv.DictReader(open(f'{R}/docs/targets_B.csv', encoding='utf-8-sig')) for b in r['group'].split('+')}
    ta = {r['slot']: r for r in csv.DictReader(open('levels/sweet_rope_A/work/targets_A.csv', encoding='utf-8-sig'))}
    plan = {}
    for x in csv.DictReader(open(src)):
        if abs(float(x['lech'])) <= thr or x['man'] == '1': continue
        r = ta[x['man']] if x['bo'] == 'A' else tb[(x['man'], x['bo'])]
        key = 'A|' + x['man'] if x['bo'] == 'A' else 'B|' + x['man'] + '|' + r['group']
        plan[key] = dict(key=key, ban=x['bo'] == 'A' and 'A' or 'B', row=r, cur=float(x['diem_do']), t=float(x['muc_tieu']))
    json.dump(list(plan.values()), open(f'{T}/plan.json', 'w'), ensure_ascii=False)
    print('plan', len(plan), 'A', sum(p['ban'] == 'A' for p in plan.values()), 'B', sum(p['ban'] == 'B' for p in plan.values()))
elif cmd == 'gen':
    N = int(sys.argv[3]); plan = json.load(open(f'{T}/plan.json')); items = []
    for gi, p in enumerate(plan):
        r = p['row']; s = int(r['slot']); t = p['t']; rng = random.Random(f"{p['key']}|refine")
        cap = int(r['khung_sort_streak_cap']); cups = max(8, min(14, int(r['khung_tgt']))); cols = int(r['khung_cols'])
        nt = max(8, min(10, int(r['khung_types_all']))); hid = int(r['khung_hidden']) if s >= 6 else 0
        bonus = s >= 13 and (s - 13) % 10 == 0; c = center(cap, t)
        for k in range(N):
            mix = max(0.02, min(0.30, c + rng.uniform(-0.025, 0.025)))
            short = 3 if t < 15 else 2 if t < 35 else rng.choice([1, 2])
            lock = None
            if int(r['khung_locks']) > 0 and s >= 11 and rng.random() < 0.6:
                cond = 'collect_count' if s >= 21 and rng.random() < 0.6 else 'collect_type'
                lock = (cond, rng.randint(1, 3 if cond == 'collect_count' else 2))
            drop = rng.sample(range(10), 10 - nt); types = [x for x in range(10) if x not in drop]; rng.shuffle(types)
            raw = gen.make_level(s, cap, cups, cols, nt, mix, short, max(0, hid + rng.randint(-1, 1)) if hid else 0, lock, rng,
                                 types_pref=types, need_single=bonus)
            items.append({'uid': f"{p['key']}#{k:02d}", 'raw': raw})
    json.dump(items, open(f'{T}/gen.json', 'w'))
    v = godot('validate_big.gd', f'{T}/gen.json', f'{T}/v')
    ok = {x['uid'] for x in v if x.get('valid') and x.get('solvable') != 'UNWINNABLE'}
    json.dump([x for x in items if x['uid'] in ok], open(f'{T}/ok.json', 'w')); json.dump(v, open(f'{T}/v.json', 'w'))
    print('gen', len(items), 'ok', len(ok))
elif cmd == 'screen':
    godot('greedy_screen.gd', f'{T}/ok.json', f'{T}/sc'); print('screened', len(score(f'{T}/sc_*.json')))
elif cmd == 'full':
    K = int(sys.argv[3]); plan = {p['key']: p for p in json.load(open(f'{T}/plan.json'))}; sc = score(f'{T}/sc_*.json')
    items = {x['uid']: x for x in json.load(open(f'{T}/ok.json'))}; by = {}
    for u, r in sc.items(): by.setdefault(u.split('#')[0], []).append((abs(float(r['diem_lw']) - plan[u.split('#')[0]]['t']), u))
    sel = [items[u] for k, L in by.items() for _, u in sorted(L)[:K]]
    json.dump(sel, open(f'{T}/full_in.json', 'w')); godot('greedy_ext.gd', f'{T}/full_in.json', f'{T}/ge'); print('full', len(score(f'{T}/ge_*.json')))
elif cmd == 'apply':
    plan = {p['key']: p for p in json.load(open(f'{T}/plan.json'))}; sc = score(f'{T}/ge_*.json')
    items = {x['uid']: x for x in json.load(open(f'{T}/full_in.json'))}
    v = {x['uid']: x for x in json.load(open(f'{T}/v.json'))}
    best = {}
    for u, r in sc.items():
        k = u.split('#')[0]; d = float(r['diem_lw']); lw = float(r['lw'])
        if v[u].get('solvable') != 'WINNABLE' and lw <= 0: continue
        if k not in best or abs(d - plan[k]['t']) < abs(best[k][0] - plan[k]['t']): best[k] = (d, u)
    rows = []
    for k, p in plan.items():
        r = p['row']; s = int(r['slot']); new = best.get(k)
        better = new and abs(new[0] - p['t']) < abs(p['cur'] - p['t'])
        if better:
            raw = dict(items[new[1]]['raw']); raw['id'] = s
            if p['ban'] == 'A':
                json.dump(raw, open(f'levels/sweet_rope_A/level_{s:03d}.json', 'w'), indent=2)
            else:
                json.dump(raw, open(f'{R}/work/{r["file"]}', 'w'), indent=2)
                for b in r['group'].split('+'): json.dump(raw, open(f'{R}/final/{b}/level_{s:03d}.json', 'w'), indent=2)
        rows.append(dict(ban=p['ban'], man=s, nhom=r['group'] if p['ban'] == 'B' else 'A', muc_tieu=p['t'], diem_cu=p['cur'],
                         lech_cu=round(p['cur'] - p['t'], 1), diem_moi=new[0] if new else '', lech_moi=round(new[0] - p['t'], 1) if new else '',
                         thay=bool(better), uid=new[1] if better else ''))
    w = csv.DictWriter(open(f'{T}/apply.csv', 'w', newline=''), fieldnames=list(rows[0])); w.writeheader(); [w.writerow(x) for x in rows]
    e0 = [abs(x['lech_cu']) for x in rows]; e1 = [abs(x['lech_moi']) if x['thay'] else abs(x['lech_cu']) for x in rows]
    print('thay', sum(x['thay'] for x in rows), '/', len(rows), '| sai số TB', round(sum(e0) / len(e0), 1), '->', round(sum(e1) / len(e1), 1),
          '| còn >10:', sum(v > 10 for v in e1))
