"""Recheck the delivered Sweet Rope pack using unmodified repository logic."""

import argparse
import csv
import json
import os
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from tempfile import TemporaryDirectory

from generate import TARGETS, generate
from similarity import board_features, nearest

TOOLS = Path(__file__).resolve().parent
LEVELS = TOOLS.parent
REPO = LEVELS.parents[1]
CORE = Path("scripts/gameplay/juice_sort/core")
CORPORA = (
    "juice_fallback_levels",
    "juice_sunlight_levels",
    "special_challenge_levels_v2",
)
LESSONS = {
    11: {"hidden"},
    21: {"lock"},
    41: {"ice"},
    61: {"caps"},
    96: {"rows"},
    111: {"hidden", "ice"},
    146: {"lock", "caps"},
    166: {"rows", "ice", "lock"},
}


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def copy_engine(root):
    (root / CORE).mkdir(parents=True)
    for name in ("level", "rules", "solver", "hint_planner"):
        shutil.copy2(REPO / CORE / f"juice_{name}.gd", root / CORE)
    shutil.copy2(REPO / "scripts/data/level_data/aes_decryptor.gd", root)
    for name in ("measure", "decode", "replay"):
        shutil.copy2(TOOLS / f"{name}.gd", root)
    (root / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="Sweet Rope level audit"\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n',
        encoding="utf-8",
    )


def run(root, godot, *args):
    env = dict(os.environ)
    for variable, folder in (
        ("XDG_DATA_HOME", "data"),
        ("XDG_CACHE_HOME", "cache"),
        ("XDG_CONFIG_HOME", "config"),
    ):
        env[variable] = str(root / folder)
    command = [godot, "--headless", "--path", str(root), *map(str, args)]
    subprocess.run(command, env=env, check=True)


def originals(root, godot):
    for label, file in (
        ("originals", "chapter_default_1_5"),
        ("baseline", "chapter_baseline_1_5"),
    ):
        output = root / f"{label}.json"
        run(
            root,
            godot,
            "-s",
            "res://decode.gd",
            "--",
            REPO / "assets/builtin" / f"{file}.json",
            output,
        )
        for item in read_json(output):
            yield f"{label}:{item['key']}", item["raw"]
    for name in CORPORA:
        data = read_json(REPO / "assets/game" / f"{name}.json")
        for i, raw in enumerate(data["levels"] if isinstance(data, dict) else data, 1):
            yield f"{name}:{i}", raw.get("raw", raw)


def references(root, godot):
    unique = {}
    for name, raw in originals(root, godot):
        features = board_features(raw)
        unique.setdefault(
            frozenset(features.items()), (name, features, sum(features.values()))
        )
    return list(unique.values())


def evaluate(root, godot, rows, jobs):
    def subset(index):
        src = root / f"levels-{index}.json"
        dst = root / f"checks-{index}.ndjson"
        src.write_text(json.dumps(rows[index::jobs]), encoding="utf-8")
        run(root, godot, "-s", "res://measure.gd", "--", src, dst)
        return [json.loads(line) for line in dst.read_text().splitlines()]

    with ThreadPoolExecutor(max_workers=jobs) as executor:
        return {
            int(result["id"]): result
            for group in executor.map(subset, range(jobs))
            for result in group
        }


def mechanics(raw):
    columns = raw["initial"] + raw["incoming"]
    caps = raw.get("columnCaps", {})
    tests = {
        "hidden": any("?" in x["column"] for x in columns),
        "lock": any(x["columnType"] == "unlock" for x in raw["initial"]),
        "ice": "sunlight" in raw and any("i" in x["column"] for x in raw["initial"]),
        "caps": len(set(caps.get("initial", []) + caps.get("incoming", []))) > 1,
        "rows": raw.get("layoutRows") == 2,
    }
    return {name for name, active in tests.items() if active}


def check_progression(raw, record, number):
    active = mechanics(raw)
    assert active == set(filter(None, record["co_che"].split("+"))), number
    for start, required in LESSONS.items():
        if start <= number < start + 5:
            assert active == required, number
            break
    else:
        introduced = {
            flag for start, flags in LESSONS.items() if start < number for flag in flags
        }
        assert len(active) <= 1 and active <= introduced, number
    level_type = "Hard" if number % 5 == 0 else "Normal"
    assert raw["note"] == f"Chapter {(number - 1) // 25 + 1} · {level_type}", number


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--godot", default="godot", help="path to the Godot 4.6.1 executable"
    )
    parser.add_argument("--jobs", type=int, choices=range(1, 5), default=2)
    args = parser.parse_args()
    version = subprocess.check_output([args.godot, "--version"], text=True).strip()
    if not version.startswith("4.6.1."):
        parser.error(f"Godot 4.6.1 required, got {version}")
    rows = [read_json(LEVELS / f"level_{number:03}.json") for number in range(1, 201)]
    with (LEVELS / "report.csv").open(encoding="utf-8-sig", newline="") as file:
        report = list(csv.DictReader(file))
    assert len(report) == len(rows) == 200
    assert len({row["seed"] for row in rows}) == len(rows)
    for start in LESSONS:
        scores = [
            float(entry["diem_uoc_luong"]) for entry in report[start - 1 : start + 4]
        ]
        assert all(a < b for a, b in zip(scores, scores[1:])), (start, scores)

    with TemporaryDirectory(prefix="sweet-rope-verify-") as directory:
        root = Path(directory)
        copy_engine(root)
        run(root, args.godot, "--editor", "--import", "--quit")
        metrics = evaluate(root, args.godot, rows, args.jobs)
        refs = references(root, args.godot)
        new_boards = []
        seen = set()
        for n, (raw, record) in enumerate(zip(rows, report), 1):
            result = metrics[n]
            assert raw["id"] == n == int(record["man"]), n
            target = int(record["diem_muc_tieu"])
            assert target == TARGETS[n - 1], n
            source_id, attempt = divmod(raw["seed"], 1000000)
            regenerated = generate(source_id, attempt)
            regenerated.update(id=n, note=raw["note"])
            assert raw["seed"] == int(record["seed"]) and regenerated == raw, n
            assert (
                not result["errors"]
                and result["status"] == record["solvable"] == "WINNABLE"
            ), n
            assert int(result["expanded"]) == int(record["expanded"]), n
            for key, field, precision in (
                ("score", "diem_uoc_luong", 3),
                ("win_rate", "win_rate", 4),
                ("branch", "branch", 4),
            ):
                assert (
                    abs(result[key] - float(record[field]))
                    <= 0.5 * 10**-precision + 1e-9
                ), (n, key, result[key])
            check_progression(raw, record, n)
            features = board_features(raw)
            shape = frozenset(features.items())
            assert shape not in seen, n
            seen.add(shape)
            assert nearest(features, new_boards)[0] < 0.7, n
            new_boards.append((str(n), features, sum(features.values())))
            similarity, source = nearest(features, refs)
            assert similarity < 0.7, (n, similarity)
            assert (
                abs(similarity - float(record["similarity_original"])) <= 0.00000051
            ), n
            assert source == record["nearest_original"], n

        src, dst = root / "lessons.json", root / "replay.ndjson"
        src.write_text(
            json.dumps([row for row in rows if row["id"] in LESSONS]), encoding="utf-8"
        )
        run(root, args.godot, "-s", "res://replay.gd", "--", src, dst)
        for line in dst.read_text().splitlines():
            result = json.loads(line)
            number = int(result["id"])
            assert result["won"], number
            for mechanic, event in (
                ("hidden", "revealed"),
                ("lock", "unlocked"),
                ("ice", "melted"),
            ):
                if mechanic in LESSONS[number]:
                    assert result["events"][event] > 0, (number, event)
            print(result)
    print(f"Verified 200 levels against {len(refs)} source signatures with {version}.")


if __name__ == "__main__":
    main()
