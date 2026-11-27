"""So đặc trưng từng level mới với level default cùng số. In mỗi đặc trưng: giữ / đổi ở bao nhiêu level."""
import json, collections, sys
import trial_gen as G

C = lambda lv: [r['container']['type'] for r in lv['ropes'] if r.get('container')]
Q = lambda lv: [e['container']['type'] for e in lv.get('reserveQueue', []) if e.get('container')]
items = G.slots
FEATURES = {
    'có Hidden': lambda lv: any(i.get('state') == 'Hidden' for i in items(lv)),
    'số Hidden': lambda lv: sum(i.get('state') == 'Hidden' for i in items(lv)),
    'số Rope có Hidden': lambda lv: sum(any(i.get('state') == 'Hidden' for i in l) for l in G.lists(lv)),
    'Locked: loại, màu, số lần': lambda lv: [(r['seal']['rule'], r['seal'].get('type'), r['seal']['count']) for r in lv['ropes'] if r.get('seal')],
    'số màu': lambda lv: len({i['type'] for i in items(lv)}),
    'số quả mỗi màu': lambda lv: sorted(collections.Counter(i['type'] for i in items(lv)).items()),
    'số Order': lambda lv: lv['orderCount'],
    'difficultyType': lambda lv: lv['difficultyType'],
    'sức chứa': lambda lv: [r['capacity'] for r in lv['ropes']],
    'số Rope, loại Rope': lambda lv: [r['kind'] for r in lv['ropes']],
    'số quả trên từng Rope lúc mở': lambda lv: [len(r['items']) for r in lv['ropes']],
    'số quả refill từng lượt': lambda lv: [len(e.get('refill', [])) for e in lv.get('reserveQueue', [])],
    'kiểu ReserveQueue': lambda lv: [e['mode'] for e in lv.get('reserveQueue', [])],
    'màu Container lúc mở': C,
    'màu chờ trong ReserveQueue (theo thứ tự)': Q,
    'màu chỉ có 1 Container, có mặt lúc mở (ứng viên Bonus)': lambda lv: sorted(t for t in set(C(lv)) if (C(lv) + Q(lv)).count(t) == 1),
    'số màu thấy được lúc mở': lambda lv: len({i['type'] for r in lv['ropes'] for i in r['items'] if i.get('state') != 'Hidden'}),
}

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    base = G.base_levels(); new = {}
    for line in open(G.RESULTS, encoding='utf8'):
        r = json.loads(line)
        if r['best']: new[r['n']] = r['best'][0]['level']
    print('level đã sinh:', sorted(new))
    for name, f in FEATURES.items():
        diff = [n for n in new if f(new[n]) != f(base[n])]
        print(f'{name:58s} giữ {len(new) - len(diff)}/{len(new)}' + (f'  đổi ở {diff}' if diff else ''))
    n = min(new); print('ví dụ level', n, {k: (FEATURES[k](base[n]), FEATURES[k](new[n])) for k in ('số Rope có Hidden', 'màu chờ trong ReserveQueue (theo thứ tự)', 'số màu thấy được lúc mở')})
