"""Weighted overlap of color-normalized rope features."""

from collections import Counter


def board_features(level):
    out = Counter()
    for role in ("initial", "incoming"):
        for i, entry in enumerate(level[role]):
            column = entry if isinstance(entry, str) else entry["column"]
            pot, _, tail = column.partition("|")
            if pot == "x":
                continue
            mapping = {}
            cap = level.get("columnCaps", {}).get(role, [])
            cap = int(cap[i]) if i < len(cap) else int(level["capacity"])
            lock = entry.get("columnInfo", {}) if not isinstance(entry, str) else {}
            label = "park" if pot == "-" else "pot"
            if pot.isdigit():
                mapping[pot] = "A"
            seq = []
            for token in tail.split(",") if tail else []:
                base = token.lstrip("?i")
                if base not in mapping:
                    mapping[base] = chr(65 + len(mapping))
                seq.append(token[: -len(base)] + mapping[base])
            # Discard rope position in both groups to catch reorder-only changes.
            prefix = (role, label)
            sig = tuple(seq)
            wt = max(1, len(seq))
            out[("rope", *prefix, lock.get("condition"), lock.get("count"), sig)] += (
                2 * wt
            )
            reduced = tuple(t.lstrip("?i") for t in sig)
            out[("plain", *prefix, reduced)] += wt
            out[("capacity", *prefix, cap, reduced)] += wt
            # A little positional credit survives local changes and hidden/ice edits.
            for j, token in enumerate(reduced):
                out[("cell", *prefix, j, token)] += 1
                if j:
                    out[("pair", *prefix, j, reduced[j - 1], token)] += 1
    return out


def score(a, b):
    common = sum(min(v, b.get(k, 0)) for k, v in a.items())
    return common


def nearest(candidate, refs, maximum=0.70):
    n = sum(candidate.values())
    best = (0.0, "")
    for name, base, weight in refs:
        den = max(n, weight)
        if min(n, weight) / den <= best[0]:
            continue
        ratio = score(candidate, base) / den
        if ratio > best[0]:
            best = (ratio, name)
        if best[0] >= maximum:
            break
    return best
