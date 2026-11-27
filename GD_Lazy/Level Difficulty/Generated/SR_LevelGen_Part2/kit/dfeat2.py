"""Supply-timeline inputs: how tight the board gets along the Order sequence, if moving Items were free.

The bot rarely survives past the first third, so it says little about the rest of a level. Here Items on unlocked Ropes
form one pool; a Container can be delivered when the pool holds `capacity` Items of its type. Each Deliver applies the
next ReserveQueue entry (new Container, Free Rope or Remove, plus refill). Slack = room left on the board, in Ropes."""
import math
from collections import Counter
from sim import Level, ttype

DEAD = -99.0


def timeline(lv):
    """Explore every delivery order (memoised). Returns slack, freedom and dead-end inputs."""
    cap, target, inc = lv.cap, lv.target, lv.inc
    ropes0 = []; pool0 = Counter()
    for kind, jar, beads, lock in lv.init:
        items = Counter(ttype(v) for v in beads)
        ropes0.append((jar, lock, items if lock else None))
        if not lock: pool0 += items

    def slack(ropes, pool):
        usable = sum(1 for jar, lock, _ in ropes if jar != -2 and not lock)
        return usable - sum(pool.values()) / cap

    def choices(ropes, pool):
        seen = set(); out = []
        for i, (jar, lock, _) in enumerate(ropes):
            if jar >= 0 and not lock and pool[jar] >= cap and jar not in seen: seen.add(jar); out.append(i)
        return out

    def deliver(ropes, pool, cups, done, i):
        ropes = list(ropes); pool = Counter(pool); cups = Counter(cups)
        t = ropes[i][0]; pool[t] -= cap; cups[t] += 1
        kind, jar, beads, lock = inc[done] if done < len(inc) else ('x', -2, [], None)
        new_jar = jar if kind == 'j' else -2
        ropes[i] = (new_jar, lock if new_jar != -2 else None, Counter() if lock else None)
        pool.update(ttype(v) for v in beads)
        done += 1
        for k, (j, lk, held) in enumerate(ropes):
            if lk and (done >= lk[2] if lk[0] == 'collect_count' else cups[lk[1]] >= lk[2]):
                ropes[k] = (j, None, None); pool.update(held or {})
        return ropes, +pool, cups, done

    memo = {}

    def best(ropes, pool, cups, done):
        """(best reachable minimum slack, number of delivery orders that finish)"""
        if done >= target: return 99.0, 1
        key = (done, tuple(sorted((j, str(l)) for j, l, _ in ropes if j != -2 or l)), tuple(sorted(pool.items())))
        if key in memo: return memo[key]
        top, n = DEAD, 0
        if len(memo) < 20000:
            for i in choices(ropes, pool):
                nxt = deliver(ropes, pool, cups, done, i)
                s, m = best(*nxt)
                n += m
                if m: top = max(top, min(slack(nxt[0], nxt[1]), s))
        memo[key] = (top, n)
        return top, n

    start = (ropes0, pool0, Counter(), 0)
    best_min, paths = best(*start)
    # greedy walk (always the delivery leaving most room): shape of the pressure over the level
    ropes, pool, cups, done = start; trace = []; widths = []
    while done < target:
        c = choices(ropes, pool)
        if not c: break
        widths.append(len(c))
        ropes, pool, cups, done = max((deliver(ropes, pool, cups, done, i) for i in c), key=lambda s: slack(s[0], s[1]))
        trace.append(slack(ropes, pool))
    third = lambda k: min(trace[k * target // 3:(k + 1) * target // 3] or [DEAD / 10])
    return dict(t_slack0=slack(start[0], start[1]),
                t_best_min=min(best_min, 20.0) if paths else DEAD / 10, t_logpaths=math.log1p(paths), t_dead=int(not paths), t_states=math.log1p(len(memo)),
                t_g_min=min(trace or [DEAD / 10]), t_g_mean=sum(trace) / len(trace) if trace else DEAD / 10, t_g_first=third(0), t_g_mid=third(1), t_g_last=third(2),
                t_g_progress=done / target, t_g_width=sum(widths) / len(widths) if widths else 0.0, t_g_forced=sum(w == 1 for w in widths) / len(widths) if widths else 1.0)


def structure(lv):
    """How deep the wanted Items are buried and when supply arrives."""
    cap = lv.cap
    ropes = [([ttype(v) for v in beads], jar, lock) for _, jar, beads, lock in lv.init]
    wanted = [jar for _, jar, lock in ropes if jar >= 0 and not lock]
    dig = []; ready = []
    for t in wanted:
        costs = sorted(sum(1 for v in items[i + 1:] if v != t) for items, _, lock in ropes if not lock for i, v in enumerate(items) if v == t)
        have = len(costs); ready.append(min(have, cap) / cap)
        dig.append((sum(costs[:cap]) + max(0, cap - have) * cap) / cap)
    on_board = Counter(v for items, _, _ in ropes for v in items)
    total = Counter(on_board)
    for _, _, beads, _ in lv.inc: total.update(ttype(v) for v in beads)
    arrived = Counter(on_board); lag = []; free_at = []; remove_at = []
    queued = Counter()
    for k, (kind, jar, beads, lock) in enumerate(lv.inc):
        arrived.update(ttype(v) for v in beads)
        pos = k / max(1, lv.target - 1)
        if kind == 'j' and jar >= 0:
            queued[jar] += 1; lag.append(1 - arrived[jar] / total[jar] if total[jar] else 1.0)
        elif kind == 'j': free_at.append(pos)
        else: remove_at.append(pos)
    conts = Counter(wanted) + queued
    refill = [len(b) for _, _, b, _ in lv.inc if b]
    # buried disorder: pairs where an Item sits on top of a different type
    cover = sum(1 for items, _, _ in ropes for i in range(1, len(items)) if items[i] != items[i - 1])
    n_items = sum(len(items) for items, _, _ in ropes)
    mean = lambda a, d=0.0: sum(a) / len(a) if a else d
    locks = [lock for _, _, lock in ropes if lock]
    return dict(s_dig_min=min(dig or [cap]), s_dig_mean=mean(dig, cap), s_ready_max=max(ready or [0]), s_ready_mean=mean(ready), s_lag_mean=mean(lag), s_lag_max=max(lag or [0]),
                s_free_first=min(free_at or [1.0]), s_free_n=len(free_at), s_remove_first=min(remove_at or [1.0]), s_remove_n=len(remove_at),
                s_cont_max=max(conts.values() or [0]), s_cont_types=len(conts), s_refill_mean=mean(refill) / cap, s_refill_max=max(refill or [0]) / cap,
                s_cover=cover / max(1, n_items), s_fill=n_items / (len(ropes) * cap), s_lock_need=sum(l[2] for l in locks) / max(1, lv.target),
                s_dup_init=len(wanted) - len(set(wanted)))


def feats2(layout):
    bare = layout if '?' not in str(layout) else __import__('json').loads(__import__('json').dumps(layout).replace('?', ''))
    lv = Level(bare)
    out = structure(lv); out.update(timeline(lv))
    return out


def selftest():
    c = lambda s: {'column': s, 'columnType': 'default', 'columnInfo': {}}
    # two Containers, everything on the board: both orders finish, room never shrinks below the start
    easy = dict(capacity=3, targetCups=2, initial=[c('0|0,1,0'), c('1|1,0,1'), c('-|'), c('-|')], incoming=[])
    f = feats2(easy)
    assert f['t_dead'] == 0 and abs(f['t_slack0'] - 2) < 1e-9 and f['t_logpaths'] > 1.0 and f['t_g_progress'] == 1, f
    # Container 2 is never supplied -> dead
    bad = dict(capacity=3, targetCups=2, initial=[c('0|0,0,0'), c('2|'), c('-|')], incoming=[])
    assert feats2(bad)['t_dead'] == 1
    # same board with the refill arriving only after the first Deliver: finishes, with one order
    late = dict(capacity=3, targetCups=2, initial=[c('0|0,0,0'), c('1|'), c('-|')], incoming=[c('-|1,1,1')])
    f = feats2(late)
    assert f['t_dead'] == 0 and abs(f['t_logpaths'] - math.log(2)) < 1e-9, f
    print('selftest ok')


if __name__ == '__main__':
    selftest()
