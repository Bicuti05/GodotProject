"""Feature extraction for Sort Streak level difficulty. Beads bottom->top; 'jar|b,b' ; ?N hidden ; iN frozen."""
import json, math, collections

SRV = r'E:\AssetRipper\ClaudeWorkPlace\SortStreak\out\server_levels.json'
SUN = r'E:\AssetRipper\ClaudeWorkPlace\SortStreak\out\GodotProject\assets\game\juice_sunlight_levels.json'
FB = r'E:\AssetRipper\ClaudeWorkPlace\SortStreak\out\GodotProject\assets\game\juice_fallback_levels.json'


def parse_col(c):
    j, _, b = c['column'].partition('|')
    beads = []
    for x in (b.split(',') if b else []):
        kind = 'n'
        if x.startswith('?'): kind, x = 'h', x[1:]
        elif x.startswith('i'): kind, x = 'f', x[1:]
        beads.append((int(x), kind))
    return j, beads


def feats(layout, sunlight_type=None):
    cap = layout['capacity']; tgt = layout['targetCups']
    cols = layout['initial']; inc = layout['incoming']
    f = collections.OrderedDict()
    f['cap'] = cap; f['tgt'] = tgt; f['cols'] = len(cols)
    types = set(); jars = []; parks = empty = 0
    nb = nh = nf = 0
    hid_buried = 0       # hidden beads not at the top of their column
    hid_depth = 0        # sum of (beads above it)
    wrong = 0            # beads not equal to own column jar (jar columns only)
    buried_wrong = 0     # beads sitting above a wrong bead... (disorder)
    changes = 0          # adjacent type changes within columns
    pure = 0
    locks = lk_count = lk_type = lk_count_sum = lk_type_sum = 0
    lock_beads = 0
    tops_match = 0
    for c in cols:
        j, bs = parse_col(c)
        is_lock = c['columnType'] == 'unlock'
        if j == '-': parks += 1
        else: jars.append(int(j)); types.add(int(j))
        if not bs and not is_lock and j != '-': empty += 1
        if not bs and j == '-': empty += 1
        n = len(bs)
        for i, (t, k) in enumerate(bs):
            types.add(t); nb += 1
            if k == 'h':
                nh += 1
                if i != n - 1: hid_buried += 1
                hid_depth += (n - 1 - i)
            if k == 'f': nf += 1
            if j != '-' and t != int(j): wrong += 1
            if i and bs[i - 1][0] != t: changes += 1
        if n and len({t for t, _ in bs}) == 1: pure += 1
        if is_lock:
            locks += 1; lock_beads += n
            info = c['columnInfo']
            if info.get('condition') == 'collect_type':
                lk_type += 1; lk_type_sum += info.get('count', 1)
            else:
                lk_count += 1; lk_count_sum += info.get('count', 1)
        if bs and j != '-' and bs[-1][0] == int(j) and bs[-1][1] == 'n': tops_match += 1
    f['types_init'] = len(types)
    f['beads_init'] = nb
    f['free_slots'] = len(cols) * cap - nb
    f['free_ratio'] = (len(cols) * cap - nb) / (len(cols) * cap)
    f['parks'] = parks; f['empty_cols'] = empty
    f['dup_jars'] = len(jars) - len(set(jars))
    f['hidden'] = nh; f['hidden_buried'] = hid_buried; f['hidden_depth'] = hid_depth
    f['hidden_ratio'] = nh / nb if nb else 0
    f['frozen'] = nf
    f['wrong_ratio'] = wrong / nb if nb else 0
    f['changes_per_col'] = changes / len(cols)
    f['pure_cols'] = pure
    f['tops_match'] = tops_match
    f['locks'] = locks; f['lk_count'] = lk_count; f['lk_type'] = lk_type
    f['lk_count_sum'] = lk_count_sum; f['lk_type_sum'] = lk_type_sum; f['lock_beads'] = lock_beads
    # incoming
    ij = ip = ir = 0; ib = ihid = 0; itypes = set(); inc_len = len(inc); inc_changes = 0
    for c in inc:
        j = c['column'].partition('|')[0]
        _, bs = parse_col(c) if j not in ('x', '') else (None, [])
        if j == '-': ip += 1
        elif j == 'x': ir += 1
        else: ij += 1; itypes.add(int(j))
        for i, (t, k) in enumerate(bs):
            ib += 1; types.add(t)
            if k == 'h': ihid += 1
            if i and bs[i - 1][0] != t: inc_changes += 1
        if c['columnType'] == 'unlock': f['lock_in_inc'] = f.get('lock_in_inc', 0) + 1
    f.setdefault('lock_in_inc', 0)
    f['inc_len'] = inc_len; f['inc_jar'] = ij; f['inc_park'] = ip; f['inc_retire'] = ir
    f['inc_beads'] = ib; f['inc_hidden'] = ihid; f['inc_changes'] = inc_changes
    f['types_all'] = len(types)
    f['beads_all'] = nb + ib
    f['supply_ratio'] = (nb + ib) / (tgt * cap) if tgt * cap else 0
    f['init_share'] = nb / (nb + ib) if nb + ib else 0
    f['cols_final'] = len(cols) - ir   # rough: columns remaining after retirements
    f['sunlight'] = 1 if sunlight_type is not None else 0
    return f


def load_server():
    D = json.load(open(SRV, encoding='utf8'))
    out = []
    for e in D:
        out.append(dict(tag=e['levelUserTags'], ch=e['chapterIndex'], idx=e['levelIndex'], uid=e['levelUniqueId'],
                        diff=int(e['difficulty']), score=float(e['summaryScore']), hard=int(e['difficultyType'] == 'Hard'),
                        f=feats(e['layout'])))
    return out
