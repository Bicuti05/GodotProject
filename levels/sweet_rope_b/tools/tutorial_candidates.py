"""Generate fresh tutorial boards, with no dependency on reference levels."""

import argparse
import json
import random
from pathlib import Path


def column(pot, beads):
    return {
        "column": f"{pot}|" + ",".join(map(str, beads)),
        "columnType": "default",
        "columnInfo": {},
    }


def shape(rows):
    """Ignore the color labels and order of the initial ropes."""
    ropes = []
    for pot, beads in rows:
        mapping = {} if pot == "-" else {pot: 0}
        pattern = tuple(mapping.setdefault(bead, len(mapping)) for bead in beads)
        ropes.append((pot == "-", pattern))
    return tuple(sorted(ropes))


def generate(seed, count):
    rng = random.Random(seed)
    seen = set()
    candidates = []
    while len(candidates) < count:
        colors = rng.sample(range(10), 3)
        stock = colors * 3
        rng.shuffle(stock)
        lengths = rng.choice([(2, 2, 2, 3), (0, 3, 3, 3), (1, 2, 3, 3)])
        lengths = rng.sample(lengths, len(lengths))
        rows = []
        index = 0
        for pot, length in zip(["-", *colors], lengths):
            rows.append((pot, stock[index : index + length]))
            index += length
        if any(pot != "-" and beads == [pot] * 3 for pot, beads in rows):
            continue
        signature = shape(rows)
        if signature in seen:
            continue
        seen.add(signature)
        raw = {
            "id": 1,
            "capacity": 3,
            "targetCups": 3,
            "initial": [column(pot, beads) for pot, beads in rows],
            "incoming": [column("x", []), column("x", [])],
        }
        candidates.append({"uid": f"L001_pending_{len(candidates) + 1:03}", "raw": raw})
    return candidates


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--seed", type=int, default=421830)
    parser.add_argument("--count", type=int, choices=range(1, 31), default=30)
    args = parser.parse_args()
    args.output.write_text(json.dumps(generate(args.seed, args.count), indent=2) + "\n")


if __name__ == "__main__":
    main()
