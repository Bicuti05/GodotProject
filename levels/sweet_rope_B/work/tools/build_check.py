#!/usr/bin/env python3
"""Gom bản đề xuất + K ứng viên gần mục tiêu nhất (theo điểm tự chấm) để bên kiểm chấm lại.
build_check.py targets.csv workdir out.json K [file1,file2,...]"""
import json, csv, os, sys
T, W, OUT, K = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
only = set(sys.argv[5].split(',')) if len(sys.argv) > 5 and sys.argv[5] else None
items = []
for r in csv.DictReader(open(T, encoding='utf-8-sig')):
    f = r['file']
    if only is not None and f not in only: continue
    if not os.path.exists(f'{W}/{f}'): continue
    base = f[:-5]; t = float(r['muc_tieu']); off = json.load(open(f'{W}/{f}')); seen = {json.dumps(off, sort_keys=True)}
    items.append({'uid': base + '_OFF', 'raw': off})
    cp = f'{W}/candidates/{f}'
    cs = json.load(open(cp)) if os.path.exists(cp) else []
    def key(c):
        d = c.get('diem_lw', c.get('diem_tu_uoc_luong'))
        return abs(float(d) - t) if d not in (None, '') else 999
    n = 0
    for i, c in enumerate(sorted(cs, key=key)):
        k = json.dumps(c['raw'], sort_keys=True)
        if k in seen: continue
        seen.add(k); items.append({'uid': f'{base}_c{i:02d}', 'raw': c['raw']}); n += 1
        if n >= K: break
json.dump(items, open(OUT, 'w')); print(len(items))
