"""3-phase level metrics: static start view + information-limited bot playouts + stuck causes. Max 6 workers, BELOW_NORMAL."""
import random, json, sys, time
from multiprocessing import Pool
from sim import *
from dfeat import feats, SUN, SRV

N = 40
CAUSES = ('no_empty_rope', 'locked_left', 'ice_left', 'root_blocked')
HIDDEN = ('hidden', 'hidden_buried', 'hidden_depth', 'hidden_ratio', 'inc_hidden')


def causes(st):
    live = [i for i in range(len(st['cols'])) if not st['gone'][i]]
    items = [v for i in live for v in st['cols'][i]]
    jars = [i for i in live if st['jars'][i] >= 0]
    return dict(no_empty_rope=not any(not st['cols'][i] and not st['locks'][i] for i in live),
                locked_left=any(st['locks'][i] for i in live),
                ice_left=any(frozen(v) for v in items) or any(st['fp']),
                root_blocked=bool(jars) and all(st['cols'][i] and st['cols'][i][0] != st['jars'][i] for i in jars))


def start_view(lv):
    """What the player sees on opening: initial ropes only (ReserveQueue is not shown)."""
    st = lv.state(); ms = moves(st)
    vis = [v for c in st['cols'] for v in c if not hidden(v)]
    merge = {(m[0], m[2]) for m in ms if st['cols'][m[2]]}
    return dict(v_items=len(vis), v_types=len({ttype(v) for v in vis}), v_moves=len({(m[0], m[2]) for m in ms}),
                v_merges=len(merge), v_free=free_slots(st), v_empty=sum(1 for i, c in enumerate(st['cols']) if not c and not st['locks'][i]),
                frozen_pots=sum(st['fp']))


def bot_metrics(lv, seed, n=N):
    rng = random.Random(seed)
    m = dict(win=0, progress=0, moves_per_order=0, stuck_early=0, stuck_mid=0, stuck_end=0)
    for p in ('early', 'mid', 'end'): m['free_' + p] = 0; m['minfree_' + p] = 0; m['seen_' + p] = 0
    for c in CAUSES: m['cause_' + c] = 0
    stuck = 0
    for _ in range(n):
        tr = []
        ok, nm = bot_play(lv, rng, max_moves=250, trace=tr)
        st = tr[-1][2]; prog = min(1, st['done'] / lv.target)
        m['win'] += ok; m['progress'] += prog; m['moves_per_order'] += nm / max(1, st['done'])
        for k, p in enumerate(('early', 'mid', 'end')):
            fr = [f for d, f, _ in tr if min(2, 3 * d // lv.target) == k]
            if fr: m['seen_' + p] += 1; m['free_' + p] += sum(fr) / len(fr); m['minfree_' + p] += min(fr)
        if not ok:
            stuck += 1
            m['stuck_' + ('early', 'mid', 'end')[min(2, 3 * st['done'] // lv.target)]] += 1
            for c, v in causes(st).items(): m['cause_' + c] += v
    for p in ('early', 'mid', 'end'):
        s = m.pop('seen_' + p)
        m['reach_' + p] = s / n
        for k in ('free_', 'minfree_'): m[k + p] = m[k + p] / s if s else 0
    for k in ('win', 'progress', 'moves_per_order'): m[k] /= n
    # conditional stuck rate: of the playouts that reached this phase, how many died in it
    for p in ('early', 'mid', 'end'):
        m['stuck_' + p] = m['stuck_' + p] / (m['reach_' + p] * n) if m['reach_' + p] else 1.0   # never reached = counts as fully stuck
    for c in CAUSES: m['cause_' + c] /= max(1, stuck)
    return m


def measure(layout, seed=0, n=N):
    # The bot cannot make use of hidden information, so all inputs except HIDDEN are measured with every item shown.
    # Hidden is then scored only by the HIDDEN inputs, which the model may only count upwards.
    bare = json.loads(json.dumps(layout).replace('?', ''))
    lv = Level(bare); real = feats(layout)
    f = dict(feats(bare)); f.update({k: real[k] for k in HIDDEN})
    f.update(start_view(lv)); f.update(bot_metrics(lv, seed, n))
    return f


def lowprio():
    import ctypes
    k = ctypes.windll.kernel32
    k.GetCurrentProcess.restype = ctypes.c_void_p          # without these types the 64-bit handle is truncated and the call silently fails
    k.SetPriorityClass.argtypes = [ctypes.c_void_p, ctypes.c_uint32]
    assert k.SetPriorityClass(k.GetCurrentProcess(), 0x4000), 'could not set BELOW_NORMAL'


def work(job):
    k, layout = job
    return k, measure(layout, seed=k)


def jobs():
    D = json.load(open(SRV, encoding='utf8')); seen = {}
    for e in D:
        seen.setdefault(json.dumps(e['layout'], sort_keys=True), e['layout'])
    for e in json.load(open(SUN, encoding='utf8')):
        seen.setdefault(json.dumps(e['raw'], sort_keys=True), e['raw'])
    return list(seen)


if __name__ == '__main__':
    keys = jobs()
    J = [(i, json.loads(k)) for i, k in enumerate(keys)]
    if len(sys.argv) > 1: J = random.Random(1).sample(J, int(sys.argv[1]))
    t = time.time(); out = {}
    with Pool(6, initializer=lowprio) as p:
        for i, (k, r) in enumerate(p.imap_unordered(work, J, chunksize=4)):
            out[keys[k]] = r
            if i % 1000 == 0: print(i, len(J), round(time.time() - t), flush=True)
    json.dump(out, open('sim3_out.json' if len(sys.argv) == 1 else 'sim3_test.json', 'w')); print('done', len(out), round(time.time() - t))
