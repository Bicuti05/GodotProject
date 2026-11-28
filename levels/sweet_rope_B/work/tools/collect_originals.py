#!/usr/bin/env python3
"""Gom mọi level có sẵn trong project thành [{uid, raw}] (dạng Godot) để kiểm trùng lặp.
Nguồn: assets/builtin, assets/game (JSON Godot), thư mục LevelDesigner/Levels (Unity: pack, variant, challenge),
GD_Lazy trên branch main (Unity/Godot), bản A cũ (git show <rev>:levels/sweet_rope_A/level_###.json).
Dùng: collect_originals.py out.json LEVELDESIGNER_DIR OLD_A_REV"""
import json, sys, glob, subprocess, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../../checks/tools'))
OUT, LD, REV = sys.argv[1], sys.argv[2], sys.argv[3]
out = []


def unity_to_raw(L):
    def items(lst):
        return ','.join(('?' if i.get('state') == 'Hidden' else '') + str(i['type']) for i in lst)
    caps = set(); init = []
    for r in L['ropes']:
        caps.add(r['capacity']); c = r.get('container')
        pot = '-' if (r.get('kind') == 'Free' or c is None) else str(c['type'])
        init.append({'column': f"{pot}|{items(r.get('items', []))}"})
    inc = []
    for q in L.get('reserveQueue', []):
        if q['mode'] == 'Remove': inc.append({'column': 'x|'}); continue
        pot = '-' if q['mode'] == 'Free' else str(q['container']['type'])
        inc.append({'column': f"{pot}|{items(q.get('refill', []))}"})
    return {'capacity': max(caps), 'targetCups': L.get('orderCount', 0), 'initial': init, 'incoming': inc}


def walk(x, src):
    if isinstance(x, dict):
        if 'initial' in x and 'incoming' in x and 'capacity' in x:
            out.append({'uid': f'{src}#{len(out)}', 'raw': x}); return
        if 'ropes' in x and 'orderCount' in x:
            try: out.append({'uid': f'{src}#{len(out)}', 'raw': unity_to_raw(x)})
            except Exception: pass
            return
        for v in x.values(): walk(v, src)
    elif isinstance(x, list):
        for v in x: walk(v, src)


for f in glob.glob('assets/builtin/**/*.json', recursive=True) + glob.glob('assets/game/*.json'):
    try: walk(json.load(open(f)), f)
    except Exception: pass
for f in glob.glob(f'{LD}/**/*.json', recursive=True):
    walk(json.load(open(f)), 'LevelDesigner/' + os.path.relpath(f, LD))
files = subprocess.run(['git', 'ls-tree', '-r', '--name-only', 'origin/main', '--', 'GD_Lazy'], capture_output=True, text=True).stdout.split('\n')
for f in files:
    if not f.endswith('.json'): continue
    try: walk(json.loads(subprocess.run(['git', 'show', f'origin/main:{f}'], capture_output=True, text=True).stdout), f)
    except Exception: pass
for n in range(1, 201):
    try:
        raw = json.loads(subprocess.run(['git', 'show', f'{REV}:levels/sweet_rope_A/level_{n:03d}.json'], capture_output=True, text=True).stdout)
        out.append({'uid': f'A_cu/level_{n:03d}', 'raw': raw})
    except Exception: pass
json.dump(out, open(OUT, 'w'))
import collections
print(len(out), collections.Counter(u['uid'].split('/')[0].split('#')[0] for u in out).most_common(12))
