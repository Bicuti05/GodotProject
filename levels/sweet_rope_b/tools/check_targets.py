"""Validate coverage of the authoritative Version B target CSV before generation."""

import argparse
import csv
import math
from pathlib import Path


BOOKS = frozenset(("default", "lv2", "lv3", "lv4", "lv5"))


def load_targets(path):
    with path.open(encoding="utf-8-sig", newline="") as file:
        reader = csv.DictReader(file)
        required = {"slot", "group", "loai", "muc_tieu", "dac_biet",
                    "bat_buoc_bonus_1_mau_1_chau", "file"}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise ValueError("Missing columns: " + ", ".join(sorted(missing)))
        rows = list(reader)

    keys = set()
    files = set()
    scores = set()
    for row in rows:
        slot = int(row["slot"])
        books = row["group"].split("+")
        target = float(row["muc_tieu"])
        filename = row["file"]
        if not (1 <= slot <= 200 and math.isfinite(target)):
            raise ValueError(f"Invalid slot or target: {row}")
        if not set(books) <= BOOKS or len(books) != len(set(books)):
            raise ValueError(f"Invalid tier group at slot {slot}: {books}")
        if slot <= 5 and set(books) != BOOKS:
            raise ValueError(f"Slot {slot} must be shared across the five tiers")
        if not filename.endswith(".json") or Path(filename).name != filename or "\\" in filename:
            raise ValueError(f"Invalid filename: {filename!r}")
        if filename in files or (slot, target) in scores:
            raise ValueError(f"Duplicate filename or unmerged target at slot {slot}")
        files.add(filename)
        scores.add((slot, target))
        for book in books:
            key = (book, slot)
            if key in keys:
                raise ValueError(f"Duplicate assignment: {key}")
            keys.add(key)

    if len(rows) != 681 or len(keys) != 1000:
        raise ValueError(f"Expected 681 groups and 1000 assignments, got {len(rows)} and {len(keys)}")
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("targets", type=Path)
    args = parser.parse_args()
    try:
        rows = load_targets(args.targets)
    except (OSError, ValueError, TypeError) as error:
        parser.error(str(error))
    print(f"{len(rows)} groups cover all five tiers and all 200 slots.")


if __name__ == "__main__":
    main()
