#!/usr/bin/env python3
"""Chuyển level Unity (sweetrope.levelpack/1) sang JSON đọc được bằng JuiceLevel.from_dict (Godot) để kiểm bằng engine.
Cách dùng: python3 unity_to_juice.py pack_001.json [pack_002.json ...] > levels.json   (mảng [{uid, raw}])
Quy ước: thứ tự quả giữ nguyên (đã đối chiếu màn 1 với Sort Streak). Rope Free -> "-|", Locked giữ chậu và thêm khóa:
TypedDelivery -> collect_type (thiếu type = màu 0), AnyDelivery -> collect_count. reserveQueue: Container -> "<màu>|...",
Free -> "-|...", Remove -> "x|". Hidden -> "?", Ice/Frozen -> "i".
Lưu ý: Godot cấm hoa ẩn ở cuối mục incoming (validate), Unity thì cho phép và lộ ngay khi thành đuôi."""
import json, sys
def items(lst):
    return ','.join(('?' if i.get('state') == 'Hidden' else ('i' if i.get('state') in ('Frozen', 'Ice') else '')) + str(i['type']) for i in lst)
def conv(L, n):
    caps = set(); init = []
    for r in L['ropes']:
        caps.add(r['capacity']); c = r.get('container')
        pot = '-' if (r['kind'] == 'Free' or c is None) else str(c['type'])
        col = {'column': f"{pot}|{items(r['items'])}", 'columnType': 'default', 'columnInfo': {}}
        if r['kind'] == 'Locked':
            s = r['seal']
            info = {'condition': 'collect_count', 'count': s['count']} if s['rule'] == 'AnyDelivery' else {'condition': 'collect_type', 'typeId': s.get('type', 0), 'count': s['count']}
            col = {'column': col['column'], 'columnType': 'unlock', 'columnInfo': info}
        init.append(col)
    inc = []
    for q in L['reserveQueue']:
        if q['mode'] == 'Remove':
            inc.append({'column': 'x|', 'columnType': 'default', 'columnInfo': {}}); continue
        caps.add(q['capacity'])
        pot = '-' if q['mode'] == 'Free' else str(q['container']['type'])
        inc.append({'column': f"{pot}|{items(q.get('refill', []))}", 'columnType': 'default', 'columnInfo': {}})
    if len(caps) != 1:
        raise ValueError(f'level {n}: nhiều sức chứa {caps} (cần columnCaps)')
    return {'id': n, 'capacity': caps.pop(), 'targetCups': L['orderCount'], 'initial': init, 'incoming': inc}
out = []
for f in sys.argv[1:]:
    p = json.load(open(f))
    for s in p['stages']:
        for L in s['levels']:
            n = (s['stage'] - 1) * 25 + L['levelIndex']
            out.append({'uid': f'L{n:04d}', 'raw': conv(L, n)})
json.dump(out, sys.stdout)
