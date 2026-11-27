"""Searching players: noisy beam search with a few skill levels. How often each one finishes a board is the strongest
difficulty input found so far (rank correlation about 0.7 with Sort Streak summaryScore; static inputs stay under 0.3).

A player sees every Item (Hidden removed) and keeps the `width` best boards at each step."""
import random, json
import sim

# name: (width, noise, runs, weights)
BASE = dict(done=40.0, wrong=1.0, breaks=2.0, empty=3.0, room=0.5, buried=1.0)
PLAYERS = {
    'p1': (1, 4.0, 24, {}),
    'p2': (2, 4.0, 24, dict(room=0.0, empty=1.0)),
    'p3': (3, 6.0, 24, {}),
    'p3b': (3, 6.0, 16, dict(wrong=0.0, breaks=3.0)),
    'p4': (4, 8.0, 10, {}),
}
FEATURES = [f'{n}_{k}' for n in PLAYERS for k in ('win', 'done')]


def play(lv, width, noise, w, rng, depth=160):
    """one attempt -> (finished, share of Orders delivered)"""
    front = [lv.state()]; seen = {sim.key(front[0])}; best = 0
    for _ in range(depth):
        nxt = []
        for st in front:
            for m in sim.moves(st):
                t = sim.clone(st); sim.apply(t, lv, m); k = sim.key(t)
                if k in seen: continue
                seen.add(k)
                if sim.won(t, lv): return 1, 1.0
                if t['done'] > best: best = t['done']
                if sim.doomed(t, lv): continue
                wrong = breaks = buried = empty = room = 0
                for i, col in enumerate(t['cols']):
                    if t['gone'][i] or t['locks'][i]: continue
                    jar = t['jars'][i]; room += t['caps'][i] - len(col)
                    if not col: empty += 1; continue
                    prev = None; bad = False
                    for v in col:
                        x = v % 1000
                        if jar >= 0:
                            if x != jar: wrong += 1; bad = True
                            elif bad: buried += 1                  # a right Item sitting above a wrong one
                        if prev is not None and prev != x: breaks += 1
                        prev = x
                s = (-w['done'] * t['done'] + w['wrong'] * wrong + w['breaks'] * breaks + w['buried'] * buried
                     - w['empty'] * empty - w['room'] * room)
                nxt.append((s + rng.gauss(0, noise), len(nxt), t))
        if not nxt: break
        nxt.sort(); front = [t for _, _, t in nxt[:width]]
    return 0, best / lv.target


def player_feats(layout, seed=0, players=PLAYERS):
    lv = sim.Level(json.loads(json.dumps(layout).replace('?', '')))
    out = {}
    for k, (name, (width, noise, runs, weights)) in enumerate(players.items()):
        w = dict(BASE, **weights); rng = random.Random(seed * 1000 + k)
        r = [play(lv, width, noise, w, rng) for _ in range(runs)]
        out[name + '_win'] = sum(a for a, _ in r) / runs; out[name + '_done'] = sum(b for _, b in r) / runs
    return out


def selftest():
    c = lambda s: {'column': s, 'columnType': 'default', 'columnInfo': {}}
    easy = dict(capacity=3, targetCups=2, initial=[c('0|0,1,0'), c('1|1,0,1'), c('-|'), c('-|')], incoming=[])
    f = player_feats(easy)
    assert f['p3_win'] == 1 and f['p3_done'] == 1 and f == player_feats(easy), f
    stuck = dict(capacity=3, targetCups=2, initial=[c('0|0,1,0'), c('1|1,0,1')], incoming=[])
    assert player_feats(stuck)['p4_win'] == 0
    print('selftest ok')


if __name__ == '__main__':
    selftest()
