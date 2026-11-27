"""Fit the add-on formula for design numbers outside the Sort Streak data (writes bonus.json).

The trees are flat outside the data they saw, so every unit beyond the range adds slope * units.
free / types / hidden slopes come from paired edits on real levels: change one thing, keep the bot results,
and read how much the fitted model moves. orders / capacity cannot be edited that way and use a linear regression.
Run with:  python -X utf8 fit_bonus.py   (about 5 minutes, 6 workers, below-normal priority)"""
import json, random, collections
from multiprocessing import Pool
import numpy as np
from dfeat import SRV, feats
from sim3 import measure, lowprio, HIDDEN
from level_score import load_model

SAMPLE = 400


def head(c):
    return c['column'].partition('|')[0]


def items(c):
    return [x for x in c['column'].partition('|')[2].split(',') if x]


def add_free(L):
    L = json.loads(json.dumps(L))
    for c in L['incoming']:
        if head(c) == 'x':
            c['column'] = '-|'; return L
    return None


def merge_types(L, rng):
    L = json.loads(json.dumps(L)); cols = L['initial'] + L['incoming']
    types = sorted({x.lstrip('?i') for c in cols for x in items(c)})
    a, b = rng.sample(types, 2)
    for c in cols:
        h = head(c)
        if h == 'x': continue
        body = [x.replace(b, a) for x in items(c)]
        c['column'] = (a if h == b else h) + '|' + ','.join(body)
    return L


def total(model, f):
    m = model['models']['default']
    s = m['base'] + sum(float(t.predict([[f[n] for n in names]])[0]) - 0 for p, names in model['phases'].items() for t in m['mods'][p]) - sum(m['low'].values())
    return min(100.0, max(0.0, s))


def one(job):
    k, L, kind = job
    rng = random.Random(k)
    f = measure(L, seed=k)
    if kind == 'hidden':
        edited = dict(f); edited.update({n: 0 for n in HIDDEN})
        return kind, f, edited, f['hidden'] + f['inc_hidden']
    L2 = add_free(L) if kind == 'free' else merge_types(L, rng)
    bare = json.loads(json.dumps(L2).replace('?', ''))
    edited = dict(f); edited.update({n: v for n, v in feats(bare).items() if n not in HIDDEN})   # static inputs change, bot results stay
    return kind, f, edited, 1


def design(e):
    L = e['layout']; cols = L['initial'] + L['incoming']
    its = [x for c in cols for x in items(c)]
    return dict(capacity=L['capacity'], orders=L['targetCups'], types=len({x.lstrip('?i') for x in its}),
                free=sum(head(c) == '-' for c in cols), hidden=sum(x[0] == '?' for x in its))


def main():
    D = [e for e in json.load(open(SRV, encoding='utf8')) if e['levelUserTags'] == 'default']
    R = [design(e) for e in D]
    ranges = {k: [min(r[k] for r in R), max(r[k] for r in R)] for k in R[0]}
    ranges['types'] = [8, 10]; ranges['capacity'] = [4, 6]; ranges['orders'] = [10, 14]      # a handful of levels sit outside these
    rng = random.Random(7); jobs = []
    pools = dict(free=[e for e, r in zip(D, R) if r['free'] == 2], types=[e for e, r in zip(D, R) if r['types'] == 9],
                 hidden=[e for e, r in zip(D, R) if r['hidden'] >= 5])
    for kind, pool in pools.items():
        jobs += [(len(jobs) + i, e['layout'], kind) for i, e in enumerate(rng.sample(pool, min(SAMPLE, len(pool))))]
    with Pool(6, initializer=lowprio) as p:
        out = p.map(one, jobs, chunksize=4)
    model = load_model()
    raw = collections.defaultdict(list)
    for kind, f, edited, units in out:
        if kind == 'hidden': raw[kind].append((total(model, f) - total(model, edited)) / units)
        else: raw[kind].append(total(model, edited) - total(model, f))
    y = np.array([float(e['summaryScore']) for e in D])
    keys = ['capacity', 'orders', 'types', 'free', 'hidden']
    X = np.array([[1] + [r[k] for k in keys] for r in R], float); b = np.linalg.lstsq(X, y, rcond=None)[0]
    mean = {k: float(np.mean(v)) for k, v in raw.items()}
    se = {k: float(np.std(v) / len(v) ** 0.5) for k, v in raw.items()}
    # slope = score change per unit ABOVE the range; direction is fixed by the game rules, a wrong-way estimate becomes 0
    slope = dict(free=min(0.0, mean['free']), types=max(0.0, -mean['types']), hidden=max(0.0, mean['hidden']),
                 capacity=max(0.0, float(b[1])), orders=max(0.0, float(b[2])))
    res = dict(ranges=ranges, slope=slope, paired_mean=mean, paired_se=se, regression=dict(zip(keys, map(float, b[1:]))),
               source=dict(free='paired edit', types='paired edit', hidden='paired edit', capacity='regression', orders='regression'))
    json.dump(res, open('bonus.json', 'w'), indent=2)
    print(json.dumps(res, indent=2))


if __name__ == '__main__':
    main()
