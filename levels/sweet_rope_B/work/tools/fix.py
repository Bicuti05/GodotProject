#!/usr/bin/env python3
"""Sửa toàn bộ level vi phạm luật (repair.py) và chọn phương án sửa gần mục tiêu nhất.
Các bước (chạy lần lượt, từ gốc repo):
  fix.py gen    TMP K   -> K phương án sửa mỗi level lỗi
  fix.py screen TMP     -> chấm nhanh (greedy_screen.gd)
  fix.py full   TMP M   -> chấm đầy đủ M bản gần mục tiêu nhất (greedy_ext.gd); bản bot không thắng thì kiểm solver
  fix.py random TMP     -> bot chơi bừa cho màn đầu cần dễ (A 2-9, B 2-5, B default 6-9)
  fix.py apply  TMP     -> ghi level, TMP/apply.csv"""
import json, csv, os, sys, random, subprocess
sys.path.insert(0, os.path.dirname(__file__))
import repair as RP
R = 'levels/sweet_rope_B'
cmd, T = sys.argv[1], sys.argv[2]
os.makedirs(T, exist_ok=True)


def godot(script, inp, outp, shards=4):
    ps = [subprocess.Popen(['godot', '--headless', '--path', '.', '-s', f'res://.godot/{script}', '--', inp, f'{outp}_{i}.json', str(i), str(shards)],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) for i in range(shards)]
    for p in ps: p.wait()
    out = []
    for i in range(shards):
        try: out += json.load(open(f'{outp}_{i}.json'))
        except Exception: pass
    return out


def score(pattern):
    out = subprocess.run(['python3', f'{R}/tools/score.py', pattern], capture_output=True, text=True).stdout
    return {r['uid']: r for r in csv.DictReader(out.splitlines())}


def targets():
    L = []
    ta = {int(r['man']): float(r['diem_muc_tieu']) for r in csv.DictReader(open('levels/sweet_rope_A/report.csv', encoding='utf-8-sig'))}
    for n in range(1, 201):
        L.append(dict(key=f'A|{n}', ban='A', slot=n, t=ta[n], path=f'levels/sweet_rope_A/level_{n:03d}.json', easy=2 <= n <= 9))
    for r in csv.DictReader(open(f'{R}/docs/targets_B.csv', encoding='utf-8-sig')):
        s = int(r['slot']); g = r['group']
        L.append(dict(key=f'B|{s}|{g}', ban='B', slot=s, t=float(r['muc_tieu']), group=g, file=r['file'],
                      path=f"{R}/final/{g.split('+')[0]}/level_{s:03d}.json", easy=(2 <= s <= 5) or (g == 'default' and 6 <= s <= 9)))
    return L


if cmd == 'gen':
    K = int(sys.argv[3]); items = []; plan = []
    for p in targets():
        raw = json.load(open(p['path']))
        if RP.violations(raw) == 0: continue
        plan.append(p)
        for k in range(K):
            new = RP.repair(raw, random.Random(f"{p['key']}|{k}"))
            if new: items.append({'uid': f"{p['key']}#{k}", 'raw': new})
    json.dump(plan, open(f'{T}/plan.json', 'w')); json.dump(items, open(f'{T}/gen.json', 'w'))
    print('plan', len(plan), 'variants', len(items))
elif cmd == 'screen':
    godot('greedy_screen.gd', f'{T}/gen.json', f'{T}/sc'); print('screened', len(score(f'{T}/sc_*.json')))
elif cmd == 'full':
    M = int(sys.argv[3]); plan = {p['key']: p for p in json.load(open(f'{T}/plan.json'))}; sc = score(f'{T}/sc_*.json')
    items = {x['uid']: x for x in json.load(open(f'{T}/gen.json'))}; by = {}
    for u, r in sc.items():
        k = u.split('#')[0]; by.setdefault(k, []).append((float(r['lw']) <= 0, abs(float(r['diem_lw']) - plan[k]['t']), u))
    sel = [items[u] for k, L in by.items() for _, _, u in sorted(L)[:M]]
    json.dump(sel, open(f'{T}/full_in.json', 'w')); godot('greedy_ext.gd', f'{T}/full_in.json', f'{T}/ge')
    ge = score(f'{T}/ge_*.json')
    nowin = [x for x in sel if x['uid'] in ge and float(ge[x['uid']]['lw']) <= 0]
    json.dump(nowin, open(f'{T}/solve_in.json', 'w'))
    if nowin: godot('validate_big.gd', f'{T}/solve_in.json', f'{T}/v')
    print('full', len(ge), 'need solver', len(nowin))
elif cmd == 'random':
    plan = {p['key']: p for p in json.load(open(f'{T}/plan.json'))}
    easy = [x for x in json.load(open(f'{T}/gen.json')) if plan[x['uid'].split('#')[0]]['easy']]
    json.dump(easy, open(f'{T}/easy_in.json', 'w')); godot('random_bot.gd', f'{T}/easy_in.json', f'{T}/rb'); print('random', len(easy))
elif cmd == 'apply':
    plan = {p['key']: p for p in json.load(open(f'{T}/plan.json'))}
    items = {x['uid']: x for x in json.load(open(f'{T}/gen.json'))}
    ge = score(f'{T}/ge_*.json'); sc = score(f'{T}/sc_*.json')
    v = {}
    for i in range(4):
        try:
            for x in json.load(open(f'{T}/v_{i}.json')): v[x['uid']] = x
        except Exception: pass
    rb = {}
    for i in range(4):
        try:
            for x in json.load(open(f'{T}/rb_{i}.json')):
                s = x['cfg'][0]['seeds']; w = sum(a['win'] for a in s) / len(s); dn = sum(a['done'] for a in s) / len(s)
                rb[x['uid']] = (w, (dn - w) / (1 - w) if w < 1 else 1.0)
        except Exception: pass
    rows = []
    for k, p in plan.items():
        cands = []
        for u in [x for x in items if x.startswith(k + '#')]:
            if p['easy']:
                if u not in rb: continue
                w, ld = rb[u]; d = float((ge.get(u) or sc.get(u) or {'diem_lw': 0})['diem_lw'])
                need = 1.0 if p['slot'] <= 5 else 0.95
                cands.append(((0 if w >= need else 1), -w if w < need else 0, abs(d - p['t']), u, d, w)); continue
            if u not in ge: continue
            lw = float(ge[u]['lw']); d = float(ge[u]['diem_lw'])
            if lw <= 0 and v.get(u, {}).get('solvable') != 'WINNABLE': continue
            cands.append((0, 0, abs(d - p['t']), u, d, None))
        if not cands:
            rows.append(dict(ban=p['ban'], man=p['slot'], nhom=p.get('group', 'A'), muc_tieu=p['t'], diem_moi='', lech='', choi_bua='', ket_qua='KHONG SUA DUOC')); continue
        c = min(cands); u = c[3]; raw = dict(items[u]['raw']); raw['id'] = p['slot']
        json.dump(raw, open(p['path'], 'w'), indent=2)
        if p['ban'] == 'B':
            for b in p['group'].split('+'): json.dump(raw, open(f"{R}/final/{b}/level_{p['slot']:03d}.json", 'w'), indent=2)
            json.dump(raw, open(f"{R}/work/{p['file']}", 'w'), indent=2)
        rows.append(dict(ban=p['ban'], man=p['slot'], nhom=p.get('group', 'A'), muc_tieu=p['t'], diem_moi=c[4], lech=round(c[4] - p['t'], 1),
                         choi_bua=round(c[5] * 100) if c[5] is not None else '', ket_qua='da_sua'))
    w = csv.DictWriter(open(f'{T}/apply.csv', 'w', newline=''), fieldnames=list(rows[0])); w.writeheader(); [w.writerow(x) for x in rows]
    e = [abs(x['lech']) for x in rows if x['lech'] != '']
    print('sua', len(e), '/', len(rows), '| sai so TB', round(sum(e) / len(e), 1), '| >10:', sum(x > 10 for x in e), '| khong sua duoc', len(rows) - len(e))
