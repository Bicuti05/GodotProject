"""Bộ kiểm nhanh cho người (hoặc AI) sinh level Sweet Rope. Đọc README_LevelGen.md trước.

  python -X utf8 sr_levelkit.py selftest
  python -X utf8 sr_levelkit.py check <thư mục Levels default> <thư mục Levels mới> [--levels 2-200 | --only todo_levels.txt] [--workers 4]

check ghi vào <thư mục Levels mới>/../kit_out/: report.csv (từng level) và solutions.json (lời giải từng level).
Một level ĐẠT khi: không lỗi khung, giải được, và |điểm nhanh - đích nhanh| <= 2.31."""
import csv, json, os, sys, heapq, collections
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import sim
from trial_gen import to_layout, slots, hideable, lists, hidden_range, MIN_CHANGED

PACKS = ('pack_001.json', 'pack_002.json')
TOL = 2.31
BONUS = lambda n: n >= 13 and (n - 13) % 10 == 0
# Challenge and Endless replace these levels while playing, so the default board may stay
REPLACED = lambda n: (n >= 17 and (n - 17) % 10 == 0) or (n >= 30 and (n - 30) % 10 == 0)


def load(levels_dir):
    out = {}
    for f in PACKS:
        for s in json.load(open(os.path.join(levels_dir, f), encoding='utf8'))['stages']:
            for l in s['levels']: out[(s['stage'] - 1) * 25 + l['levelIndex']] = l
    return out


def targets():
    return {int(r['level']): r for r in csv.DictReader(open(os.path.join(HERE, 'targets.csv'), encoding='utf-8-sig'))}


def containers(lv):
    return [r for r in lv['ropes'] if r.get('container')] + [e for e in lv.get('reserveQueue', []) if e.get('container')]


def gold(lv):
    first = [r['container']['type'] for r in lv['ropes'] if r.get('container')]
    every = [o['container']['type'] for o in containers(lv)]
    return sorted(t for t in set(first) if every.count(t) == 1)


def frame_errors(new, base, n):
    """what breaks the frame rules of README section 3 (empty list = ok)"""
    if n == 1: return [] if new == base else ['level 1 phải giữ nguyên (hướng dẫn gắn cứng)']
    if REPLACED(n) and new == base: return []
    e = []
    same = lambda what, f: e.append(f'đổi {what}') if f(new) != f(base) else None
    same('orderCount', lambda l: l['orderCount'])
    same('difficultyType', lambda l: l['difficultyType'])
    same('Rope lúc mở (loại, sức chứa, số quả, có Container)', lambda l: [(r['kind'], r['capacity'], len(r['items']), bool(r.get('container'))) for r in l['ropes']])
    same('màu Container lúc mở', lambda l: [r['container']['type'] for r in l['ropes'] if r.get('container')])
    same('kiểu khoá', lambda l: [(r.get('seal') or {}).get('rule') for r in l['ropes']])
    same('ReserveQueue (kiểu, sức chứa, số quả refill)', lambda l: [(q['mode'], q.get('capacity'), len(q.get('refill', []))) for q in l.get('reserveQueue', [])])
    same('số Container mỗi màu', lambda l: sorted(collections.Counter(o['container']['type'] for o in containers(l)).items()))
    same('số quả mỗi màu', lambda l: sorted(collections.Counter(i['type'] for i in slots(l)).items()))
    if e: return e                                       # the checks below assume the same shape
    if new.get('meltType') is not None or any(i.get('state') == 'Ice' for i in slots(new)) or any((r.get('container') or {}).get('frozen') for r in new['ropes']):
        e.append('không làm Ice')
    lo, hi = hidden_range(base); h = sum(i.get('state') == 'Hidden' for i in slots(new))
    if not lo <= h <= hi: e.append(f'số Hidden {h} ngoài khoảng {lo}-{hi}')
    for k, r in enumerate(new['ropes']):
        c = r.get('container')
        if r['items'] and r['items'][-1].get('state') == 'Hidden': e.append(f'Rope {k}: quả trên cùng lúc mở là Hidden')
        if c and len(r['items']) == r['capacity'] and all(i['type'] == c['type'] for i in r['items']): e.append(f'Rope {k}: đã đủ quả đúng màu lúc mở')
        s = r.get('seal')
        if s:
            others = [o for o in containers(new) if o is not r]
            need = sum(o['container']['type'] == s.get('type', 0) for o in others) if s['rule'] == 'TypedDelivery' else len(others)
            if not 1 <= s['count'] <= need: e.append(f'Rope {k}: khoá cần {s["count"]} lần, chỉ có {need} Container mở được nó')
    changed = sum(x['type'] != y['type'] for x, y in zip(slots(new), slots(base))) / len(slots(base))
    if changed < MIN_CHANGED: e.append(f'mới đổi {changed:.0%} vị trí quả, cần ít nhất {MIN_CHANGED:.0%}')
    if BONUS(n) and not gold(new): e.append('level Bonus mất màu có đúng 1 chậu')
    if not 1 <= new.get('difficulty', 0) <= 6: e.append('difficulty phải 1-6')
    return e


def find_path(level, node_cap=40000):
    """winning move list [[src, j, dst], ...] under the game rules (no Helper), or [] if none found"""
    lv = sim.Level(to_layout(level)); st = lv.state()
    nodes = [(st, -1, None)]; pq = [(sim.h_cost(st, lv), 0, 0)]; seen = {sim.key(st)}
    while pq and len(nodes) < node_cap:
        _, g, k = heapq.heappop(pq); st = nodes[k][0]
        if sim.won(st, lv):
            path = []
            while nodes[k][1] >= 0: path.append(list(nodes[k][2])); k = nodes[k][1]
            return path[::-1]
        if sim.doomed(st, lv): continue
        for m in sim.moves(st):
            t = sim.clone(st); sim.apply(t, lv, m); kk = sim.key(t)
            if kk in seen: continue
            seen.add(kk); nodes.append((t, k, m))
            heapq.heappush(pq, ((g + 1) * 0.2 + sim.h_cost(t, lv), g + 1, len(nodes) - 1))
    return []


def aim_fast(base, t):
    """the target on the quick-score scale: quick score of the default board + (curve C - real summaryScore)"""
    import sr_score
    return max(0.0, sr_score.fast(to_layout(base)) + float(t['curve_c']) - float(t['real_default']))


def check_one(job):
    import sr_score
    n, new, base, t = job
    row = dict(level=n, target_curve=t['curve_c'], notes=t['notes'])
    errs = frame_errors(new, base, n)
    row['frame_errors'] = '; '.join(errs)
    kept = n == 1 or (REPLACED(n) and new == base)
    path = [] if errs else find_path(new)
    row['solvable'] = bool(path) or kept
    if not kept and not errs:
        row['aim_fast'] = round(aim_fast(base, t), 2); row['score_fast'] = round(sr_score.fast(to_layout(new)), 2)
        row['off_by'] = round(row['score_fast'] - row['aim_fast'], 2)
    row['ok'] = kept or (not errs and bool(path) and abs(row.get('off_by', 99)) <= TOL)
    return row, path


def check(base_dir, new_dir, levels, workers):
    base, new, T = load(base_dir), load(new_dir), targets()
    jobs = [(n, new[n], base[n], T[n]) for n in levels]
    with Pool(workers) as p:
        res = p.map(check_one, jobs, chunksize=1)
    out = os.path.join(os.path.dirname(os.path.abspath(new_dir)), 'kit_out'); os.makedirs(out, exist_ok=True)
    cols = ['level', 'ok', 'frame_errors', 'solvable', 'aim_fast', 'score_fast', 'off_by', 'target_curve', 'notes']
    with open(os.path.join(out, 'report.csv'), 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, cols); w.writeheader(); [w.writerow(r) for r, _ in res]
    json.dump({str(r['level']): p for r, p in res}, open(os.path.join(out, 'solutions.json'), 'w'))
    ok = sum(r['ok'] for r, _ in res)
    print(f'ĐẠT {ok}/{len(res)} | lỗi khung {sum(bool(r["frame_errors"]) for r, _ in res)} | không giải được {sum(not r["solvable"] for r, _ in res)} | kết quả ở {out}')


def selftest():
    import copy, random
    base_dir = os.path.join(HERE, 'default_levels')
    base = load(base_dir); n = 12; lv = copy.deepcopy(base[n])
    assert frame_errors(lv, base[n], n) and 'mới đổi' in frame_errors(lv, base[n], n)[-1]
    bad = copy.deepcopy(lv); bad['orderCount'] += 1; assert 'đổi orderCount' in frame_errors(bad, base[n], n)
    import trial_gen
    boards = [trial_gen.start(base[n], random.Random(k), 0.9) for k in range(12)]
    assert all(not frame_errors(g, base[n], n) for g in boards), [frame_errors(g, base[n], n) for g in boards]
    assert find_path(base[n]) and not find_path(dict(base[n], orderCount=base[n]['orderCount'] + 1)), 'solver must win the default board and fail an impossible one'
    assert frame_errors(base[1], base[1], 1) == []
    print('selftest ok')


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    a = sys.argv[1:]
    if a[:1] == ['selftest']: selftest()
    elif a[:1] == ['check'] and len(a) >= 3:
        if '--only' in a:
            levels = [int(x) for x in open(a[a.index('--only') + 1]).read().split()]
        else:
            lo, hi = map(int, (a[a.index('--levels') + 1] if '--levels' in a else '1-200').split('-')); levels = range(lo, hi + 1)
        check(a[1], a[2], levels, int(a[a.index('--workers') + 1]) if '--workers' in a else 4)
    else: print(__doc__)
