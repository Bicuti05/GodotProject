#!/usr/bin/env python3
"""Chuyển level Godot (JuiceLevel JSON) sang level Unity `sweetrope.levelpack/1` (ngược với levels/checks/tools/unity_to_juice.py).
Quy ước: "-|" -> rope Free; collect_type -> Locked TypedDelivery; collect_count -> Locked AnyDelivery;
incoming "x|" -> Remove, "-|.." -> Free, "<màu>|.." -> Container; "?t" -> Hidden.
difficulty 1-6 suy từ điểm mục tiêu (0-100) nếu có; difficultyType theo tham số."""
import json


def items(s):
    out = []
    for t in [x for x in s.split(',') if x]:
        if t.startswith('?'): out.append({'type': int(t[1:]), 'state': 'Hidden'})
        elif t.startswith('i'): out.append({'type': int(t[1:]), 'state': 'Ice'})
        else: out.append({'type': int(t)})
    return out


def diff_bucket(score):
    # ngưỡng suy từ Sort Streak (pack_001/002 màn 1-200 so với summaryScore): 1 < 20,5 ≤ 2 < 38 ≤ 3 < 55 ≤ 4 < 70 ≤ 5 < 85 ≤ 6
    if score is None: return 1
    s = float(score)
    for i, th in enumerate([20.5, 38, 55, 70, 85]):
        if s < th: return i + 1
    return 6


def convert(raw, level_index, difficulty_type='Normal', score=None):
    cap = int(raw['capacity']); ropes = []
    for c in raw['initial']:
        pot, _, fl = c['column'].partition('|')
        r = {'kind': 'Free' if pot == '-' else 'Normal', 'capacity': cap}
        if pot != '-': r['container'] = {'type': int(pot)}
        if c.get('columnType') == 'unlock':
            ci = c['columnInfo']
            r['kind'] = 'Locked'
            r['seal'] = ({'rule': 'TypedDelivery', 'type': int(ci.get('typeId', 0)), 'count': int(ci['count'])}
                         if ci.get('condition') == 'collect_type' else {'rule': 'AnyDelivery', 'count': int(ci['count'])})
        r['items'] = items(fl)
        ropes.append(r)
    q = []
    for c in raw['incoming']:
        pot, _, fl = c['column'].partition('|')
        if pot in ('x', ''): q.append({'mode': 'Remove'}); continue
        e = {'mode': 'Free' if pot == '-' else 'Container', 'capacity': cap}
        if pot != '-': e['container'] = {'type': int(pot)}
        e['refill'] = items(fl)
        q.append(e)
    return {'levelIndex': level_index, 'difficultyType': difficulty_type, 'difficulty': diff_bucket(score),
            'orderCount': int(raw['targetCups']), 'ropes': ropes, 'reserveQueue': q}


def build_packs(levels):
    """levels: dict số_màn -> level Unity (levelIndex đã đặt). Trả dict pack_no -> pack JSON (125 màn/pack, 25 màn/stage)."""
    packs = {}
    for n in sorted(levels):
        stage = (n - 1) // 25 + 1; pno = (stage - 1) // 5 + 1
        p = packs.setdefault(pno, {'format': 'sweetrope.levelpack/1', 'pack': pno, 'stages': []})
        if not p['stages'] or p['stages'][-1]['stage'] != stage: p['stages'].append({'stage': stage, 'levels': []})
        p['stages'][-1]['levels'].append(levels[n])
    return packs
