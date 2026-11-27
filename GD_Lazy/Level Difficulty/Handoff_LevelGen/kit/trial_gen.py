"""Sinh bàn mới cho level 2-200 theo đường độ khó C, giữ khung cơ chế của bàn default cùng số level.

  python -X utf8 trial_gen.py --check     kiểm bộ đổi định dạng và các phép đổi bàn
  python -X utf8 trial_gen.py             sinh level 2-200 (6 tiến trình, chạy lại thì tiếp tục)

Khung giữ nguyên: loại Rope, sức chứa, Rope nào khoá và kiểu khoá, kiểu ReserveQueue, số Order, số Item mỗi màu, có Hidden hay không.
Được đổi (GD 26/11): số Hidden (trong hidden_range), điều kiện khoá (số lần, màu cần giao), thứ tự màu chờ, số màu thấy lúc mở.
Thay đổi: Item nằm ở đâu, Hidden Item nằm ở đâu, thứ tự màu Container trong ReserveQueue.
Level 1 giữ nguyên vì hướng dẫn gắn cứng với bàn đó. Không làm Ice (GD bỏ qua): các số level Ice vẫn có bàn thường,
bộ ice_01 của game giữ nguyên."""
import collections, json, os, random, sys, time
from multiprocessing import Pool

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = r'E:\AssetRipper\ClaudeWorkPlace\sweet-rope-sorting-puzzle\Assets\_IEC\Resources\LevelData'
OUT = os.path.join(HERE, 'Generated', 'SR_trial_S1-3')
RESULTS = os.path.join(OUT, 'results.jsonl')
LEVELS = range(2, 201)
PACKS = ('pack_001.json', 'pack_002.json')                # levels 1-250
MIN_CHANGED = 0.25                                      # share of Item positions that must differ from the default board
copy = lambda x: json.loads(json.dumps(x))


def base_levels():
    out = {}
    for f in PACKS:
        d = json.load(open(os.path.join(GAME, f), encoding='utf8'))
        out.update({(s['stage'] - 1) * 25 + l['levelIndex']: l for s in d['stages'] for l in s['levels']})
    return out


def real_scores():
    out = {}
    for e in json.load(open(r'E:\AssetRipper\ClaudeWorkPlace\SortStreak\out\server_levels.json', encoding='utf8')):
        if e['levelUserTags'] == 'default': out[(e['chapterIndex'] - 1) * 25 + e['levelIndex']] = float(e['summaryScore'])
    return out


def targets():
    import openpyxl
    ws = openpyxl.load_workbook(os.path.join(HERE, 'SR_Difficulty Curve.xlsx'), read_only=True, data_only=True)['Đường Sweet Rope']
    return {r[0]: float(r[4]) for r in ws.iter_rows(min_row=2, max_row=LEVELS[-1] + 1, values_only=True)}


def to_layout(lv):
    """Sweet Rope level -> the layout the Python rules and the score read"""
    ropes, queue = lv['ropes'], lv.get('reserveQueue', [])
    caps = {r['capacity'] for r in ropes} | {e['capacity'] for e in queue if 'capacity' in e}
    assert len(caps) == 1, ('one capacity per level expected', caps)

    def col(head, items, seal=None):
        body = ','.join(('?' if i.get('state') == 'Hidden' else '') + str(i['type']) for i in items)
        info = {}
        if seal:
            info = dict(condition='collect_type', typeId=seal.get('type', 0), count=seal['count']) if seal['rule'] == 'TypedDelivery' else dict(condition='collect_count', count=seal['count'])
        return dict(column=f'{head}|{body}', columnType='unlock' if seal else 'default', columnInfo=info)

    head = lambda r: r['container']['type'] if r.get('container') else '-'
    out = dict(capacity=caps.pop(), targetCups=lv['orderCount'], initial=[col(head(r), r['items'], r.get('seal')) for r in ropes],
               incoming=[col('x', []) if e['mode'] == 'Remove' else col(head(e), e.get('refill', [])) for e in queue])
    return out


def slots(lv):
    return [i for r in lv['ropes'] for i in r['items']] + [i for e in lv.get('reserveQueue', []) for i in e.get('refill', [])]


def hideable(lv):
    top = {id(r['items'][-1]) for r in lv['ropes'] if r['items']}      # a Hidden Item on top of an opening Rope shows at once
    return [i for i in slots(lv) if id(i) not in top]


def valid(lv, base):
    for r in lv['ropes']:
        c = r.get('container')
        if c and len(r['items']) == r['capacity'] and all(i['type'] == c['type'] for i in r['items']): return False
        if r['items'] and r['items'][-1].get('state') == 'Hidden': return False
    lo, hi = hidden_range(base)
    if not lo <= sum(i.get('state') == 'Hidden' for i in slots(lv)) <= hi: return False
    owners = [r for r in lv['ropes'] if r.get('container')] + [e for e in lv.get('reserveQueue', []) if e.get('container')]
    for r in lv['ropes']:
        s = r.get('seal')
        if not s: continue
        others = [o for o in owners if o is not r]
        if s['rule'] == 'TypedDelivery' and sum(o['container']['type'] == s.get('type', 0) for o in others) < s['count']: return False
        if s['rule'] == 'AnyDelivery' and len(others) < s['count']: return False
    a, b = slots(lv), slots(base)
    return sum(x['type'] != y['type'] for x, y in zip(a, b)) >= MIN_CHANGED * len(b)


def hidden_range(base):
    # GD 2026-11-26: the Hidden count may move; a level with no Hidden keeps none, one with Hidden keeps at least one
    h = sum(i.get('state') == 'Hidden' for i in slots(base))
    return (0, 0) if h == 0 else (max(1, h // 2), min(20, h + max(3, h // 2)))


def lists(lv):
    return [r['items'] for r in lv['ropes']] + [e['refill'] for e in lv.get('reserveQueue', []) if e.get('refill')]


def mutate(lv, rng, ops=None, easy=0.5):
    lv = copy(lv); items = slots(lv)

    def swap(a, b): a['type'], b['type'] = b['type'], a['type']

    for _ in range(ops or rng.choice((1, 1, 2, 3, 4))):
        x = rng.random()
        pairs = [(l, k) for l in lists(lv) for k in range(1, len(l))]
        if x < 0.15: swap(*rng.sample(items, 2))
        elif x < 0.75 and pairs:
            make = rng.random() < easy
            todo = [(l, k) for l, k in pairs if (l[k]['type'] != l[k - 1]['type']) == make]
            if todo:
                l, k = rng.choice(todo); want = l[k - 1]['type']
                pool = [i for i in items if (i['type'] == want) == make and i is not l[k] and i is not l[k - 1]]
                if pool: swap(l[k], rng.choice(pool))
        elif x < 0.87:                                    # Hidden: remove (more when easing), add, or move one
            on = [i for i in items if i.get('state') == 'Hidden']; off = [i for i in hideable(lv) if not i.get('state')]
            y = rng.random()
            if on and y < 0.5 * easy: rng.choice(on).pop('state')
            elif on and off and y < 0.5: rng.choice(off)['state'] = 'Hidden'
            elif on and off: rng.choice(on).pop('state'); rng.choice(off)['state'] = 'Hidden'
        elif x < 0.93 and any(r.get('seal') for r in lv['ropes']):   # lock condition: count, or the colour to deliver
            seal = rng.choice([r['seal'] for r in lv['ropes'] if r.get('seal')])   # the rule stays: it follows the unlock order
            if rng.random() < 0.5: seal['count'] = min(max(3, seal['count']), max(1, seal['count'] + (-1 if rng.random() < easy else 1)))
            elif seal['rule'] == 'TypedDelivery':
                kinds = sorted({o['container']['type'] for o in [r for r in lv['ropes'] if r.get('container')] + [e for e in lv.get('reserveQueue', []) if e.get('container')]})
                seal['type'] = rng.choice(kinds)
        else:
            q = [e['container'] for e in lv.get('reserveQueue', []) if e['mode'] == 'Container']
            if len(q) > 1: swap(*rng.sample(q, 2))
    return lv


def start(base, rng, easy=None):
    n = len(slots(base))
    for _ in range(50):
        e = rng.random() if easy is None else min(1.0, max(0.0, easy + rng.uniform(-.15, .15)))
        c = mutate(base, rng, ops=rng.randint(round(.3 * n), round(.9 * n)), easy=e)
        if valid(c, base): return c
    return None


def search(job):
    import sr_score
    from gen_level import find_path
    n, base, curve, real = job
    t0 = time.time(); rng = random.Random(n * 977 + 1); seen = set(); pool = []
    # Điểm SR reads easy boards high and hard boards low, so the aim is the curve's distance from the default board,
    # put on the SR scale: SR(default board) + (curve target - real summaryScore of that board)
    base_sr = sum(sr_score.full(to_layout(base), salt)['score'] for salt in (0, 1)) / 2
    target = max(0.0, base_sr + curve - real)

    def add(c):
        if c is None or not valid(c, base): return
        key = json.dumps(c)
        if key in seen: return
        seen.add(key); f = sr_score.fast(to_layout(c)); pool.append((abs(f - target), len(pool), c))

    # easier than the default board: mutations mostly build same-colour runs; harder: mostly break them
    easy = 0.85 if target < base_sr - 1 else 0.25 if target > base_sr + 1 else 0.5
    for _ in range(60): add(start(base, rng, easy))
    for _ in range(6):
        parents = [c for _, _, c in sorted(pool)[:10]]
        for _ in range(30): add(mutate(rng.choice(parents), rng, easy=easy))

    done = []                                            # (distance, order, record) of solvable boards with the full score

    def judge(c):
        path = find_path(to_layout(c))
        if not path: return False
        rec = dict(level=c, path=path)
        r = [sr_score.full(to_layout(c), salt) for salt in (0, 1)]
        rec.update({k: (r[0][k] + r[1][k]) / 2 for k in r[0]})
        done.append((abs(rec['score'] - target), len(done), rec))
        return True

    for _, _, c in sorted(pool):
        judge(c)
        if len(done) >= 8: break
    for _ in range(3):
        if done and min(done)[0] <= 1.5: break
        parents = [r['level'] for _, _, r in sorted(done)[:3]] or [c for _, _, c in sorted(pool)[:10]]
        kids = []
        while len(kids) < 24:
            c = mutate(rng.choice(parents), rng, easy=easy)
            if valid(c, base) and json.dumps(c) not in seen: seen.add(json.dumps(c)); kids.append(c)
        # closest by the quick score first, so the slow score is spent on promising boards
        for c in sorted(kids, key=lambda c: abs(sr_score.fast(to_layout(c)) - target))[:6]: judge(c)
    best = [r for _, _, r in sorted(done)[:3]]
    return dict(n=n, target=target, curve=curve, real=real, base_sr=base_sr, tried=len(seen), seconds=round(time.time() - t0), best=best)


def check():
    sys.path.insert(0, HERE)
    import sim
    base = base_levels(); srv = {}
    for e in json.load(open(r'E:\AssetRipper\ClaudeWorkPlace\SortStreak\out\server_levels.json', encoding='utf8')):
        if e['levelUserTags'] == 'default': srv[(e['chapterIndex'] - 1) * 25 + e['levelIndex']] = e['layout']
    for n in range(1, LEVELS[-1] + 1):
        a, b = sim.Level(to_layout(base[n])), sim.Level(srv[n])
        assert (a.cap, a.target, a.init, a.inc) == (b.cap, b.target, b.init, b.inc), ('converter differs on level', n)
    rng = random.Random(5); tally = lambda lv: sorted(i['type'] for i in slots(lv))
    for n in LEVELS:
        c = start(base[n], rng); assert c, n
        m = mutate(c, rng, ops=20)
        for x in (c, m):
            lo, hi = hidden_range(base[n])
            assert len(slots(x)) == len(slots(base[n])) and (x is m or lo <= sum(i.get('state') == 'Hidden' for i in slots(x)) <= hi), n   # m is not filtered by valid()
            assert [(r['kind'], r['capacity'], (r.get('seal') or {}).get('rule'), len(r['items'])) for r in x['ropes']] == [(r['kind'], r['capacity'], (r.get('seal') or {}).get('rule'), len(r['items'])) for r in base[n]['ropes']], n
            assert all(1 <= r['seal']['count'] for r in x['ropes'] if r.get('seal')), n
        assert tally(m) == tally(c), n
    t = targets(); assert abs(t[26] - 6.495) < .01 and abs(t[50] - 34.88) < .01 and set(t) >= set(LEVELS)
    print(f'check ok: converter equals the server layouts for {LEVELS[-1]} levels; mutations keep the frame')


if __name__ == '__main__':
    if '--check' in sys.argv: check(); sys.exit()
    from sim3 import lowprio
    base, t = base_levels(), targets(); os.makedirs(OUT, exist_ok=True)
    done = set()
    if os.path.exists(RESULTS):
        for line in open(RESULTS, encoding='utf8'):
            try: done.add(json.loads(line)['n'])
            except ValueError: pass
    real = real_scores()
    jobs = [(n, base[n], t[n], real[n]) for n in LEVELS if n not in done]
    print('levels to make', len(jobs), 'already', len(done), flush=True)
    t0 = time.time()
    with Pool(6, initializer=lowprio) as p, open(RESULTS, 'a', encoding='utf8') as f:
        for k, r in enumerate(p.imap_unordered(search, jobs, chunksize=1), 1):
            f.write(json.dumps(r) + '\n'); f.flush()
            b = r['best'][0] if r['best'] else None
            print(f"{k}/{len(jobs)} level {r['n']} target {r['target']:.1f} got {b['score']:.1f}" if b else f"{k}/{len(jobs)} level {r['n']} NO SOLVABLE BOARD", f"{r['seconds']}s", round(time.time() - t0), flush=True)
    print('done', round(time.time() - t0))
