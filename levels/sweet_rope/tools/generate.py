"""Generate original candidate layouts. Always validate candidates before use."""

import argparse
import json
import random
from pathlib import Path

TARGETS = [
    0,
    2,
    3,
    4,
    6,
    5,
    7,
    8,
    9,
    12,
    5,
    9,
    11,
    13,
    14,
    7,
    16,
    12,
    20,
    25,
    12,
    15,
    17,
    20,
    25,
    6,
    11,
    19,
    23,
    31,
    10,
    23,
    21,
    8,
    34,
    8,
    28,
    20,
    19,
    36,
    9,
    15,
    19,
    22,
    24,
    13,
    25,
    24,
    11,
    39,
    10,
    20,
    18,
    22,
    30,
    10,
    29,
    9,
    23,
    33,
    10,
    14,
    17,
    22,
    23,
    9,
    24,
    15,
    28,
    24,
    12,
    19,
    29,
    18,
    37,
    8,
    28,
    16,
    16,
    31,
    13,
    21,
    10,
    28,
    27,
    10,
    17,
    18,
    24,
    26,
    14,
    26,
    30,
    17,
    34,
    13,
    19,
    21,
    25,
    33,
    16,
    16,
    17,
    16,
    29,
    10,
    31,
    24,
    18,
    35,
    12,
    19,
    21,
    24,
    30,
    11,
    25,
    11,
    28,
    40,
    21,
    17,
    24,
    22,
    41,
    8,
    18,
    22,
    25,
    27,
    12,
    22,
    32,
    15,
    31,
    23,
    18,
    21,
    19,
    34,
    33,
    21,
    26,
    13,
    31,
    15,
    22,
    23,
    28,
    35,
    8,
    24,
    26,
    15,
    34,
    14,
    14,
    25,
    33,
    29,
    21,
    27,
    34,
    32,
    39,
    15,
    21,
    22,
    26,
    33,
    22,
    31,
    24,
    18,
    48,
    10,
    24,
    20,
    28,
    35,
    24,
    21,
    28,
    15,
    38,
    35,
    20,
    24,
    29,
    34,
    19,
    29,
    29,
    22,
    31,
    16,
    34,
    25,
    28,
    43,
]
WINDOWS = {
    11: ("hidden",),
    21: ("lock",),
    41: ("ice",),
    61: ("caps",),
    96: ("rows",),
    111: ("hidden", "ice"),
    146: ("lock", "caps"),
    166: ("rows", "ice", "lock"),
}
EXTRA = {
    "hidden": 16,
    "lock": 26,
    "ice": 46,
    "caps": 66,
    "rows": 101,
}


def mechanics(number, rng):
    for start, flags in WINDOWS.items():
        if start <= number < start + 5:
            return set(flags)
    available = [flag for flag, start in EXTRA.items() if number >= start]
    return {rng.choice(available)} if available and rng.random() < 0.34 else set()


def entry(pot, beads, lock=None):
    return {
        "column": f"{pot}|" + ",".join(map(str, beads)),
        "columnType": "unlock" if lock else "default",
        "columnInfo": lock or {},
    }


def generate(number, attempt, flags_override=None):
    seed = number * 1000000 + attempt
    rng = random.Random(seed)
    target = TARGETS[number - 1]
    flags = mechanics(number, rng) if flags_override is None else set(flags_override)
    cap = (
        4
        if "rows" in flags
        else rng.choice([2, 3, 3, 4] if number == 1 else [3, 4, 4, 5, 5, 6])
    )
    pots = rng.choice([2, 3, 3, 4] if number <= 3 else [2, 3, 4, 4, 5, 6])
    if "rows" in flags:
        pots = rng.choice([8, 8, 9, 10])
    parked = 1 if pots == 6 or (rng.random() < 0.68) else 2
    extras = rng.choices(
        [0, 1, 2, 3, 4, 5, 6],
        [1, 2, 5, 6, 3, 2, 1] if target >= 14 else [5, 6, 5, 3, 1, 1, 1],
    )[0]
    if number == 1:
        extras = rng.choice([0, 0, 0, 1])
    elif number == 2:
        extras = rng.choice([1, 2, 3])
    colors = rng.sample(range(10), pots)
    incoming = [
        rng.choice(
            colors
            if rng.random() < 0.57
            else list(set(range(10)) - set(colors)) or colors
        )
        for _ in range(extras)
    ]
    capacities = [cap] * (parked + pots + extras)
    if "caps" in flags:
        for i in rng.sample(
            range(parked, len(capacities)), rng.randint(1, max(1, (pots + extras) // 2))
        ):
            capacities[i] = rng.randint(2, cap - 1)
    n = parked + pots
    pot_labels = ["-"] * parked + colors + incoming
    # Independent stock synthesis: keep enough of each initial pot's type available,
    # then exchange stock between opening ropes and queued deliveries.
    beads = [[] for _ in range(parked)] + [
        [t] * capacities[i] for i, t in enumerate(pot_labels[parked:], parked)
    ]
    eligible = list(range(n))
    staged = "rows" in flags and attempt >= 2000 and rng.random() < 0.8
    if staged:
        eligible = list(range(parked)) + rng.sample(
            list(range(parked, n)), rng.choice([4, 5, 6])
        )
    mix = rng.choice([0.35, 0.55, 0.8, 1.1, 1.7, 2.4, 3.3])
    if number in [1, 11, 21, 41, 61, 96, 111, 146, 166]:
        mix *= 0.76
    for _ in range(max(1, round(pots * mix))):
        a, b = rng.sample(eligible, 2)
        if not beads[a] and not beads[b]:
            continue
        ai = rng.randrange(len(beads[a])) if beads[a] else None
        bi = rng.randrange(len(beads[b])) if beads[b] else None
        if ai is None:
            beads[a].append(beads[b].pop(bi))
        elif bi is None:
            beads[b].append(beads[a].pop(ai))
        elif rng.random() < 0.33 and len(beads[b]) < capacities[b]:
            beads[b].append(beads[a].pop(ai))
        else:
            beads[a][ai], beads[b][bi] = beads[b][bi], beads[a][ai]
    for _ in range(round(extras * rng.uniform(0, 1.7))):
        candidates = [i for i in range(n) if beads[i]]
        a = rng.choice(candidates)
        b = rng.randrange(n, len(beads))
        ai = rng.randrange(len(beads[a]))
        bi = rng.randrange(len(beads[b]))
        beads[a][ai], beads[b][bi] = beads[b][bi], beads[a][ai]
    # Some boards use entirely shuffled stock for a less structured alternative.
    if not staged and rng.random() < 0.26 and number not in WINDOWS:
        stock = [v for rope in beads[:n] for v in rope]
        rng.shuffle(stock)
        for i in range(n):
            k = len(beads[i])
            beads[i], stock = stock[:k], stock[k:]
    elif rng.random() < 0.70:
        for rope in beads:
            rng.shuffle(rope)
    order = list(range(n))
    rng.shuffle(order)
    if "rows" in flags:
        order = [i for i in order if i >= parked] + [i for i in order if i < parked]
    ordered_beads = [beads[i] for i in order] + beads[n:]
    ordered_pots = [pot_labels[i] for i in order] + pot_labels[n:]
    ordered_caps = [capacities[i] for i in order] + capacities[n:]
    locks = {}
    sunlight = None
    if "ice" in flags:
        active_pots = [pot_labels[i] for i in eligible if i >= parked]
        sunlight = rng.choice(active_pots)
        freezable = [
            (i, j)
            for i in range(n)
            for j, v in enumerate(ordered_beads[i])
            if v != sunlight
        ]
        for i, j in rng.sample(
            freezable,
            min(len(freezable), rng.randint(1, 2 if number in WINDOWS else 5)),
        ):
            ordered_beads[i][j] = "i" + str(ordered_beads[i][j])
    if "hidden" in flags:
        eligible = [
            (i, j)
            for i in range(n)
            for j, v in enumerate(ordered_beads[i][:-1])
            if isinstance(v, int)
        ]
        for i, j in rng.sample(
            eligible, min(len(eligible), rng.randint(1, 2 if number in WINDOWS else 5))
        ):
            ordered_beads[i][j] = "?" + str(ordered_beads[i][j])
    if "lock" in flags:
        eligible = [
            i
            for i in range(n)
            if isinstance(ordered_pots[i], int) and ordered_pots[i] != sunlight
        ]
        i = rng.choice(eligible)
        locks[i] = {
            "condition": "collect_count",
            "count": 1 if number in WINDOWS else rng.choice([1, 1, 1, 2, 3]),
        }
    initial = [
        entry(t, v, locks.get(i))
        for i, (t, v) in enumerate(zip(ordered_pots[:n], ordered_beads[:n]))
    ]
    arrivals = [entry(t, v) for t, v in zip(ordered_pots[n:], ordered_beads[n:])]
    if rng.random() < 0.33 and pots > 2:
        arrivals.insert(rng.randrange(min(2, len(arrivals)) + 1), entry("-", []))
    arrivals += [entry("x", []) for _ in range(pots + extras - 1 - len(arrivals))]
    raw = {
        "id": number,
        "capacity": cap,
        "targetCups": pots + extras,
        "initial": initial,
        "incoming": arrivals,
        "seed": seed,
        "note": f'Chapter {(number-1)//25+1} · {"Hard" if number%5==0 else "Normal"}',
    }
    if "caps" in flags:
        raw["columnCaps"] = {
            "initial": ordered_caps[:n],
            "incoming": ordered_caps[n:] + [cap] * (len(arrivals) - extras),
        }
        if len(arrivals) > extras and any(v["column"] == "-|" for v in arrivals):
            index = next(i for i, v in enumerate(arrivals) if v["column"] == "-|")
            raw["columnCaps"]["incoming"].insert(
                index, raw["columnCaps"]["incoming"].pop()
            )
    if "rows" in flags:
        raw.update(layoutRows=2, layoutColumns=4 if pots == 8 else 5)
    if sunlight is not None:
        raw["sunlight"] = {"typeId": sunlight}
    return raw


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("start", type=int, choices=range(1, 201), metavar="START")
    parser.add_argument("end", type=int, choices=range(1, 201), metavar="END")
    parser.add_argument("output", type=Path)
    parser.add_argument("--attempt-start", type=int, default=0)
    parser.add_argument("--attempts", type=int, default=20)
    args = parser.parse_args()
    if args.start > args.end or args.attempt_start < 0 or args.attempts < 1:
        parser.error("use START <= END, --attempt-start >= 0 and --attempts >= 1")
    attempts = range(args.attempt_start, args.attempt_start + args.attempts)
    candidates = [
        generate(number, attempt)
        for number in range(args.start, args.end + 1)
        for attempt in attempts
    ]
    args.output.write_text(
        json.dumps(candidates, ensure_ascii=False) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
