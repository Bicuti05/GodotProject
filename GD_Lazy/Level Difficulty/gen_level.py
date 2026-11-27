"""Sinh level Sweet Rope theo thông số và điểm độ khó đích.

Ví dụ:
  python -X utf8 gen_level.py --orders 12 --colors 7 --free 4 --hidden 20 --hidden-ropes 13 --target 10.3 --out level.json
  python -X utf8 gen_level.py --selftest

Level chỉ được nhận khi qua LevelValidator và BoardSolver của chính Sweet Rope (thư mục harness/).
Điểm = mô hình khớp Sort Streak + công thức bù cho thông số ngoài vùng dữ liệu (bonus.json).
Chưa hỗ trợ: Locked Rope, Ice, Sunlight."""
import argparse, json, os, random, subprocess, sys, tempfile, time
from multiprocessing import Pool
from sim3 import lowprio
from level_score import load_model, score
import heapq
import sim

HERE = os.path.dirname(os.path.abspath(__file__))
HARNESS = os.path.join(HERE, 'harness', 'bin', 'Release', 'net10.0', 'harness.dll')
WORKERS = 6
BONUS = json.load(open(os.path.join(HERE, 'bonus.json'), encoding='utf-8'))
PROVEN = ('Solved', 'Replayed')
NAMES = dict(capacity='sức chứa', orders='số Order', types='số màu', free='Free Rope', hidden='Hidden Item')


class Spec:
    """Everything the designer fixes. Queue layout follows the Sort Streak data:
    one Free Rope at the start, then in the ReserveQueue: Containers, extra Free entries, Remove entries."""

    def __init__(s, order, capacity, free, hidden, hidden_ropes, initial):
        s.order, s.cap, s.free, s.hidden, s.hr, s.ini = list(order), capacity, free, hidden, hidden_ropes, initial
        s.orders = len(s.order)
        s.cont0 = initial - 1                              # Containers on the board at the start
        s.qcont = s.orders - s.cont0                       # Containers arriving later
        s.qfree = free - 1
        s.remove = s.orders - 1 - s.qcont - s.qfree
        s.ropes = initial + s.qcont + s.qfree              # ropes that can hold Items
        total = s.orders * capacity
        s.items0_range = (max(total - (s.qcont + s.qfree) * capacity, round(0.55 * initial * capacity)),
                          min(total, round(0.8 * initial * capacity)))
        problems = []
        if not 3 <= s.orders <= 14: problems.append('Order phải từ 3 đến 14')
        if not 3 <= capacity <= 8: problems.append('sức chứa phải từ 3 đến 8')
        if not 2 <= initial <= 8: problems.append('số Rope lúc mở phải từ 2 đến 8')
        if s.qcont < 0: problems.append('số Order phải lớn hơn hoặc bằng số Container lúc mở')
        if free < 1: problems.append('cần ít nhất 1 Free Rope (có sẵn lúc mở)')
        if s.remove < 0: problems.append(f'quá nhiều Free Rope: tối đa {initial - 1} với {initial} Rope lúc mở')
        if s.items0_range[0] > s.items0_range[1]: problems.append('không đủ chỗ chia Item: giảm Rope lúc mở hoặc tăng sức chứa')
        if not 0 <= s.hr <= min(s.ropes, hidden) or (hidden and not s.hr): problems.append(f'số dây có Hidden phải từ 1 đến {min(s.ropes, hidden)}')
        if hidden > total - s.ini: problems.append('quá nhiều Hidden Item')
        if problems: raise ValueError('; '.join(problems))

    def extras(s):
        have = dict(capacity=s.cap, orders=s.orders, types=len(set(s.order)), free=s.free, hidden=s.hidden)
        out = {}
        for k, v in have.items():
            lo, hi = BONUS['ranges'][k]
            excess = v - min(max(v, lo), hi)
            if excess: out[k] = dict(value=v, data_range=[lo, hi], excess=excess, points=round(BONUS['slope'][k] * excess, 2))
        return out


def make_order(orders, colors, rng):
    if not 1 <= colors <= min(10, orders): raise ValueError('số màu phải từ 1 đến min(10, số Order)')
    types = rng.sample(range(10), colors)
    order = types + [rng.choice(types) for _ in range(orders - colors)]
    rng.shuffle(order)
    return order


# A candidate is a list of ropes: initial ropes first (index 0 = Free), then queue Containers, then queue Free entries.
# Each rope is a list of items bottom -> top; an item is [type, hidden].
def random_candidate(s, rng):
    items = [t for t in s.order for _ in range(s.cap)]             # sorted by Order = easiest
    for _ in range(int(rng.random() ** 2 * len(items))):            # shuffle a random amount, mostly light
        a, b = rng.randrange(len(items)), rng.randrange(len(items)); items[a], items[b] = items[b], items[a]
    n0 = rng.randint(*s.items0_range)
    sizes = spread(n0, s.ini, s.cap, rng) + spread(len(items) - n0, s.ropes - s.ini, s.cap, rng)
    it = iter(items)
    cand = [[[next(it), 0] for _ in range(n)] for n in sizes]
    return place_hidden(s, cand, rng)


def spread(total, parts, cap, rng):
    sizes = [0] * parts
    for _ in range(total):
        low = min(sizes)
        pool = [i for i in range(parts) if sizes[i] < cap and (sizes[i] <= low + 1 or rng.random() < 0.15)]
        sizes[rng.choice(pool)] += 1
    return sizes


def hideable(s, cand, r):
    # an initial rope never has a Hidden Item on top (it would be revealed at once)
    return range(len(cand[r]) - 1) if r < s.ini else range(len(cand[r]))


def place_hidden(s, cand, rng):
    for rope in cand:
        for it in rope: it[1] = 0
    if not s.hidden: return cand
    usable = [r for r in range(s.ropes) if len(hideable(s, cand, r))]
    for _ in range(200):
        if len(usable) < s.hr: return None
        chosen = rng.sample(usable, s.hr)
        if sum(len(hideable(s, cand, r)) for r in chosen) >= s.hidden: break
    else:
        return None
    spots = []
    for r in chosen:
        first = rng.choice(list(hideable(s, cand, r))); cand[r][first][1] = 1
        spots += [(r, i) for i in hideable(s, cand, r) if i != first]
    for r, i in rng.sample(spots, s.hidden - s.hr): cand[r][i][1] = 1
    return cand


def valid(s, cand):
    if cand is None or len(cand) != s.ropes or any(len(r) > s.cap for r in cand): return False
    if not s.items0_range[0] <= sum(map(len, cand[:s.ini])) <= s.items0_range[1]: return False
    for i, r in enumerate(cand[:s.ini]):
        if len(r) == s.cap and len({t for t, _ in r}) == 1: return False      # no finished rope at the start
        if r and r[-1][1]: return False
    return sum(h for r in cand for _, h in r) == s.hidden and sum(any(h for _, h in r) for r in cand) == s.hr


def mutate(s, parent, rng):
    for _ in range(100):
        c = [[list(i) for i in r] for r in parent]
        for _ in range(rng.choice((1, 1, 2, 3, 5))):
            kind = rng.random()
            spots = [(r, i) for r in range(s.ropes) for i in range(len(c[r]))]
            if kind < 0.35:                                   # swap two items (types only)
                (a, i), (b, j) = rng.sample(spots, 2); c[a][i][0], c[b][j][0] = c[b][j][0], c[a][i][0]
            elif kind < 0.6:                                  # make a pair: pull a matching type next to another
                r, i = rng.choice([p for p in spots if p[1] > 0])
                want = c[r][i - 1][0]
                src = [p for p in spots if c[p[0]][p[1]][0] == want and p not in ((r, i), (r, i - 1))]
                if src:
                    b, j = rng.choice(src); c[r][i][0], c[b][j][0] = c[b][j][0], c[r][i][0]
            elif kind < 0.75:                                 # move the top item to another rope
                a = rng.choice([r for r in range(s.ropes) if c[r]]); b = rng.choice([r for r in range(s.ropes) if r != a and len(c[r]) < s.cap] or [a])
                c[b].append(c[a].pop())
            else:                                             # lay out the Hidden Items again
                c = place_hidden(s, c, rng)
                if c is None: break
        if c is None: continue
        if sum(h for r in c for _, h in r) != s.hidden or sum(any(h for _, h in r) for r in c) != s.hr or any(r and r[-1][1] for r in c[:s.ini]):
            c = place_hidden(s, c, rng)
        if valid(s, c): return c
    return None


def to_layout(s, cand):
    col = lambda head, r: dict(column=f"{head}|" + ','.join(('?' if h else '') + str(t) for t, h in r), columnType='default', columnInfo={})
    initial = [col('-', cand[0])] + [col(s.order[i], cand[1 + i]) for i in range(s.cont0)]
    incoming = [col(s.order[s.cont0 + k], cand[s.ini + k]) for k in range(s.qcont)]
    incoming += [col('-', cand[s.ini + s.qcont + k]) for k in range(s.qfree)]
    incoming += [dict(column='x|', columnType='default', columnInfo={}) for _ in range(s.remove)]
    return dict(capacity=s.cap, targetCups=s.orders, initial=initial, incoming=incoming)


def to_sweetrope(s, cand, level_index=1, difficulty=1):
    items = lambda r: [dict(type=t, state='Hidden') if h else dict(type=t) for t, h in r]
    ropes = [dict(kind='Free', capacity=s.cap, items=items(cand[0]))]
    ropes += [dict(kind='Normal', capacity=s.cap, container=dict(type=s.order[i]), items=items(cand[1 + i])) for i in range(s.cont0)]
    queue = [dict(mode='Container', capacity=s.cap, container=dict(type=s.order[s.cont0 + k]), refill=items(cand[s.ini + k])) for k in range(s.qcont)]
    queue += [dict(mode='Free', capacity=s.cap, refill=items(cand[s.ini + s.qcont + k])) for k in range(s.qfree)]
    queue += [dict(mode='Remove') for _ in range(s.remove)]
    return dict(levelIndex=level_index, difficultyType='Normal', difficulty=difficulty, orderCount=s.orders, ropes=ropes, reserveQueue=queue)


def pack(levels):
    # the validator allows 25 levels per Stage, so larger batches are split over Stages
    for i, lv in enumerate(levels): lv['levelIndex'] = i % 25 + 1
    return dict(format='sweetrope.levelpack/1', pack=1, stages=[dict(stage=k // 25 + 1, levels=levels[k:k + 25]) for k in range(0, len(levels), 25)])


def find_path(layout, node_cap=40000):
    """A winning move list from the Python copy of the rules (greedy best-first), or []. Hidden types are not used to choose moves."""
    lv = sim.Level(layout); st = lv.state()
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


def solve(s, cands, budget, paths=None):
    """Run the game's validator, replay our winning line through the game's rules, else the game's solver.
    One (errors, status, moves) per candidate; status Replayed or Solved means proven solvable."""
    if not os.path.isfile(HARNESS):
        sys.exit('Chưa có bộ kiểm của game. Chạy: dotnet build harness -c Release')
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, 'pack.json')
        with open(path, 'w', encoding='utf-8') as f: json.dump(pack([to_sweetrope(s, c, i + 1) for i, c in enumerate(cands)]), f)
        cmd = ['dotnet', HARNESS, path, str(budget)]
        if paths is not None:
            with open(os.path.join(d, 'moves.json'), 'w') as f: json.dump(paths, f)
            cmd.append(os.path.join(d, 'moves.json'))
        r = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', timeout=1800)
    if r.returncode: raise RuntimeError(r.stderr[:800])
    rows = [line.split('|') for line in r.stdout.splitlines()]
    assert len(rows) == len(cands), (len(rows), len(cands))
    return [(row[1], row[2], int(row[3])) for row in rows]


_model = None


def evaluate(job):
    global _model
    _model = _model or load_model()
    layout, set_name, seed = job
    return score(layout, set_name, seed=seed, model=_model)


def scored(pool, s, cands, set_name, seeds):
    jobs = [(to_layout(s, c), set_name, seed) for c in cands for seed in seeds]
    res = pool.map(evaluate, jobs, chunksize=1)
    bonus = sum(x['points'] for x in s.extras().values())
    out = []
    for k in range(len(cands)):
        part = res[k * len(seeds):(k + 1) * len(seeds)]
        avg = {n: sum(p[n] for p in part) / len(part) for n in ('early', 'mid', 'end', 'base', 'total', 'bot_win')}
        avg.update(model_total=avg['total'], bonus=bonus, total=min(100.0, max(0.0, avg['total'] + bonus)))
        out.append(avg)
    return out


def generate(s, target, set_name='default', tol=0.5, rounds=40, batch=36, seed=1, budget=20000, log=print):
    """Evolve candidates toward the target. Returns (candidate, report) or (closest solvable one, report) or None."""
    rng = random.Random(seed); seeds = (0, 1, 2)
    best = []          # (distance, candidate) by single-seed score, parents of the next round
    found = []         # solvable, confirmed with 3 seeds: (distance, candidate, score, solver)
    seen = set(); t0 = time.time(); evaluated = 0
    with Pool(WORKERS, initializer=lowprio) as pool:
        for rnd in range(rounds):
            batch_c = []
            tries = 0
            while len(batch_c) < batch and tries < batch * 50:
                tries += 1
                if best and rng.random() < 0.7: c = mutate(s, rng.choice(best[:8])[1], rng)
                else: c = random_candidate(s, rng)
                key = json.dumps(c)
                if valid(s, c) and key not in seen: seen.add(key); batch_c.append(c)
            if not batch_c: break
            quick = scored(pool, s, batch_c, set_name, seeds[:1]); evaluated += len(batch_c)
            ranked = sorted(zip((abs(q['total'] - target) for q in quick), batch_c), key=lambda x: x[0])
            # only solvable boards may become parents or results
            top = [c for _, c in ranked]
            paths = pool.map(find_path, [to_layout(s, c) for c in top], chunksize=1)
            ok = {json.dumps(c) for c, (err, status, _) in zip(top, solve(s, top, budget, paths)) if status in PROVEN}
            path_of = {json.dumps(c): p for c, p in zip(top, paths)}
            best = sorted(best + [(d, c) for d, c in ranked if json.dumps(c) in ok], key=lambda x: x[0])[:16]
            close = [c for d, c in ranked if d <= tol * 2 and json.dumps(c) in ok][:6]
            if close:
                proof = solve(s, close, budget, [path_of[json.dumps(c)] for c in close])
                for c, q, p in zip(close, scored(pool, s, close, set_name, seeds), proof):
                    found.append((abs(q['total'] - target), c, q, p))
                found.sort(key=lambda x: x[0])
            lead = found[0][2]['total'] if found else None
            log(f'vòng {rnd + 1}: đã chấm {evaluated}, gần nhất (1 seed) lệch {best[0][0]:.2f}' + (f', tốt nhất 3 seed {lead:.2f}' if lead is not None else '') if best else f'vòng {rnd + 1}: chưa có bàn giải được')
            if found and found[0][0] <= tol: break
        if not found and best:
            c = best[0][1]
            found = [(0, c, scored(pool, s, [c], set_name, seeds)[0], solve(s, [c], budget, [find_path(to_layout(s, c))])[0])]
            found[0] = (abs(found[0][2]['total'] - target),) + found[0][1:]
    if not found: return None
    dist, cand, q, proof = found[0]
    report = dict(target=target, score=round(q['total'], 2), hit=dist <= tol, tolerance=tol, set=set_name,
                  phases={n: round(q[n], 2) for n in ('base', 'early', 'mid', 'end')}, model_score=round(q['model_total'], 2),
                  bonus_points=round(q['bonus'], 2), bonus_detail={NAMES[k]: v for k, v in s.extras().items()},
                  bot_win=round(q['bot_win'], 2), solver=proof[1], solver_moves=proof[2],
                  spec=dict(order=s.order, capacity=s.cap, free=s.free, hidden=s.hidden, hidden_ropes=s.hr, initial_ropes=s.ini, ropes_total=s.ropes),
                  boards_scored=evaluated, seconds=round(time.time() - t0))
    return cand, report


def selftest():
    rng = random.Random(3)
    s = Spec(make_order(12, 7, rng), capacity=5, free=4, hidden=20, hidden_ropes=13, initial=6)
    assert s.ropes == 16 and s.remove == 1, (s.ropes, s.remove)
    n = 0
    for _ in range(200):
        c = random_candidate(s, rng)
        if not valid(s, c): continue
        m = mutate(s, c, rng); assert m is None or valid(s, m)
        for x in (c, m or c):
            counts = {}
            for r in x:
                for t, _ in r: counts[t] = counts.get(t, 0) + 1
            assert counts == {t: s.order.count(t) * s.cap for t in set(s.order)}, 'item balance broken'
        n += 1
    assert n > 100, n
    errs = [e for e, _, _ in solve(s, [c for c in (random_candidate(s, rng) for _ in range(20)) if valid(s, c)], 500) if e]
    assert not errs, errs[:2]
    assert s.extras()['types']['excess'] == -1
    assert not Spec(make_order(12, 9, rng), 5, 3, 8, 6, 6).extras(), 'in-range spec must add nothing'
    for bad in (dict(free=7), dict(hidden_ropes=30), dict(capacity=9)):
        kw = dict(capacity=5, free=4, hidden=20, hidden_ropes=13, initial=6); kw.update(bad)
        try: Spec(s.order, **kw); raise AssertionError(bad)
        except ValueError: pass
    print('selftest ok', n, 'candidates')


def main():
    ap = argparse.ArgumentParser(description='Sinh level Sweet Rope theo điểm độ khó')
    ap.add_argument('--target', type=float); ap.add_argument('--orders', type=int); ap.add_argument('--colors', type=int)
    ap.add_argument('--order', help='dãy type Container theo thứ tự xuất hiện, ví dụ 1,0,2,1 (thay cho --orders/--colors)')
    ap.add_argument('--capacity', type=int, help='mặc định theo dữ liệu: 5, hoặc 6 khi điểm đích từ 20')
    ap.add_argument('--free', type=int, default=2); ap.add_argument('--hidden', type=int, default=0)
    ap.add_argument('--hidden-ropes', type=int); ap.add_argument('--initial', type=int, help='số Rope lúc mở level (gồm 1 Free); mặc định 7 khi điểm đích dưới 10, còn lại 6')
    ap.add_argument('--set', default='default', choices=['default', 'lv2', 'lv3', 'lv4', 'lv5'])
    ap.add_argument('--tol', type=float, default=0.5); ap.add_argument('--rounds', type=int, default=40); ap.add_argument('--seed', type=int, default=1)
    ap.add_argument('--out', default='generated_level.json'); ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest: return selftest()
    if a.target is None or not (a.order or (a.orders and a.colors)): ap.error('cần --target và (--order hoặc --orders cùng --colors)')
    try:
        order = [int(x) for x in a.order.split(',')] if a.order else make_order(a.orders, a.colors, random.Random(a.seed))
        if any(not 0 <= t <= 9 for t in order): raise ValueError('type phải từ 0 đến 9')
        cap = a.capacity or (6 if a.target >= 20 else 5)
        ini = a.initial or max(7 if a.target < 10 else 6, a.free + 1)
        hr = a.hidden_ropes if a.hidden_ropes is not None else min(a.hidden, round(a.hidden * 0.65))
        spec = Spec(order, cap, a.free, a.hidden, hr, ini)
    except ValueError as e:
        sys.exit(f'Thông số không hợp lệ: {e}')
    result = generate(spec, a.target, a.set, a.tol, a.rounds, seed=a.seed)
    if not result: sys.exit('Không tìm được bàn nào giải được với thông số này.')
    cand, report = result
    level = to_sweetrope(spec, cand)
    with open(a.out, 'w', encoding='utf-8') as f: json.dump(pack([level]), f, ensure_ascii=False)
    stem = os.path.splitext(a.out)[0]
    with open(stem + '.report.json', 'w', encoding='utf-8') as f: json.dump(report, f, ensure_ascii=False, indent=2)
    with open(stem + '.layout.json', 'w', encoding='utf-8') as f: json.dump(dict(layout=to_layout(spec, cand)), f)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    if not report['hit']: print(f"CHƯA ĐẠT: gần nhất {report['score']} so với đích {a.target}.")


if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    main()
