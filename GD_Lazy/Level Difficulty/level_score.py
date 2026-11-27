"""Chấm điểm độ khó 1 level: đầu phase, giữa phase, cuối phase, tổng.
Dùng:  python level_score.py level.json [--set default|lv2|lv3|lv4|lv5] [--seed 0]
       python level_score.py --selftest
level.json: layout kiểu Sort Streak (capacity, targetCups, initial, incoming), hoặc một entry server ("layout"), hoặc entry Sunlight ("raw")."""
import os, sys, json, pickle, argparse
from sim3 import measure, CAUSES

HERE = os.path.dirname(os.path.abspath(__file__))
sys.stdout.reconfigure(encoding='utf-8')


def load_model():
    with open(os.path.join(HERE, 'model.pkl'), 'rb') as f:   # our own file; never load a model.pkl from someone else
        return pickle.load(f)


def score(layout, set_name='default', seed=0, model=None):
    model = model or load_model()
    m = model['models'][set_name]
    f = measure(layout, seed=seed)
    parts = {p: float(sum(t.predict([[f[n] for n in names]])[0] for t in m['mods'][p]) - m['low'][p]) for p, names in model['phases'].items()}
    total = min(100.0, max(0.0, m['base'] + sum(parts.values())))
    label = m['levels'][sum(round(total, 1) > c for c in m['cuts'][:len(m['levels']) - 1])]
    warn = []
    if f['frozen'] or f['frozen_pots'] or layout.get('sunlight'):
        warn.append('Level có băng/Sunlight: dữ liệu khớp không có level nào như vậy, điểm chỉ mang tính tham khảo.')
    return dict(early=round(parts['early'], 1), mid=round(parts['mid'], 1), end=round(parts['end'], 1), base=round(m['base'], 1),
                total=round(total, 1), difficulty=label, mae=m['mae'], bot_win=round(f['win'], 2),
                stuck_by_phase={p: round(f['stuck_' + p], 2) for p in ('early', 'mid', 'end')},
                stuck_causes={c: round(f['cause_' + c], 2) for c in CAUSES}, warnings=warn)


def selftest():
    c = lambda s: {'column': s, 'columnType': 'default', 'columnInfo': {}}
    easy = dict(capacity=3, targetCups=2, initial=[c('0|0,1,0'), c('1|1,0,1'), c('-|'), c('-|')], incoming=[])
    model = load_model()
    r = score(easy, model=model)
    m = model['models']['default']
    assert abs(r['total'] - min(100, max(0, m['base'] + r['early'] + r['mid'] + r['end']))) < 0.2, r
    assert r == score(easy, model=model), 'cùng seed phải ra cùng điểm'
    assert r['bot_win'] > 0.5 and r['total'] < 20, r
    # the same board with Hidden Items must never score lower than with every item shown
    hid = dict(easy, initial=[c('0|?0,?1,0'), c('1|?1,?0,1'), c('-|'), c('-|')])
    for name in model['models']:
        shown, covered = score(easy, name, model=model)['total'], score(hid, name, model=model)['total']
        assert covered >= shown, (name, shown, covered)
    print('selftest ok', r['early'], r['mid'], r['end'], r['total'], '| Hidden', score(hid, model=model)['total'])


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('level', nargs='?'); ap.add_argument('--set', default='default', choices=['default', 'lv2', 'lv3', 'lv4', 'lv5'])
    ap.add_argument('--seed', type=int, default=0); ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest or not a.level:
        selftest()
    else:
        with open(a.level, encoding='utf-8') as fh:
            d = json.load(fh)
        d = d.get('layout') or d.get('raw') or d
        missing = [k for k in ('capacity', 'targetCups', 'initial', 'incoming') if k not in d]
        if missing:
            sys.exit('Thiếu trường: ' + ', '.join(missing))
        print(json.dumps(score(d, a.set, a.seed), ensure_ascii=False, indent=2))
