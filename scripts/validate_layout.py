#!/usr/bin/env python3
"""Validate vuljector-projects layout against Vuljector expectations.

See Vuljector: setup/setup_test_harness/layout.py (validate_unit_tests_dir) and
vuljector-projects/README.md.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

# Must match setup/setup_test_harness/layout.py PARSER_PATH
PARSER_PATH = "/workspace/run/unit_tests/parse_results.py"

ROOT_DIR_SKIP = frozenset({"scripts", "__pycache__"})
COMMIT_SHA_RE = re.compile(r"^[0-9a-f]{40}$", re.IGNORECASE)


def _project_dirs(root: Path) -> list[Path]:
    out: list[Path] = []
    for p in sorted(root.iterdir()):
        if not p.is_dir():
            continue
        if p.name.startswith("."):
            continue
        if p.name in ROOT_DIR_SKIP:
            continue
        out.append(p)
    return out


def _validate_project(project_dir: Path) -> list[str]:
    errors: list[str] = []
    name = project_dir.name
    rel = lambda p: str(p.relative_to(project_dir.parent))

    pj = project_dir / "project.json"
    if not pj.exists():
        errors.append(f"{name}: missing project.json")
        return errors

    try:
        data = json.loads(pj.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"{name}: invalid JSON in project.json: {exc}")
        return errors

    if not isinstance(data, dict):
        errors.append(f"{name}: project.json must be a JSON object")
        return errors

    if data.get("project") != name:
        errors.append(
            f"{name}: project.json 'project' must match directory name "
            f"(got {data.get('project')!r})"
        )

    target_dir = data.get("target_dir")
    if not isinstance(target_dir, str) or not target_dir.strip():
        errors.append(f"{name}: project.json 'target_dir' must be a non-empty string")

    main_url = str(data.get("main_repo_url", "")).strip()
    if not main_url:
        errors.append(f"{name}: project.json 'main_repo_url' must be non-empty")

    commit = str(data.get("secure_base_commit", "")).strip()
    if not commit:
        errors.append(f"{name}: project.json 'secure_base_commit' must be non-empty")
    elif not COMMIT_SHA_RE.match(commit):
        errors.append(
            f"{name}: project.json 'secure_base_commit' must be a 40-char hex SHA "
            f"(got {commit!r})"
        )

    setup = project_dir / "setup"
    for fname in ("Dockerfile", "build.sh", "project.yaml"):
        fpath = setup / fname
        if not fpath.is_file():
            errors.append(f"{name}: missing {rel(fpath)}")

    ut = project_dir / "unit_tests"
    test_sh = ut / "test.sh"
    parser_py = ut / "parse_results.py"
    if not test_sh.is_file():
        errors.append(f"{name}: missing {rel(test_sh)}")
    else:
        try:
            body = test_sh.read_text(encoding="utf-8")
        except OSError as exc:
            errors.append(f"{name}: could not read {rel(test_sh)}: {exc}")
        else:
            if PARSER_PATH not in body:
                errors.append(
                    f"{name}: {rel(test_sh)} must pipe through parse_results at "
                    f"{PARSER_PATH!r} (Vuljector validate_unit_tests_dir)"
                )
    if not parser_py.is_file():
        errors.append(f"{name}: missing {rel(parser_py)}")

    ut_cfg = data.get("unit_tests")
    if ut_cfg is not None:
        if not isinstance(ut_cfg, dict):
            errors.append(f"{name}: project.json 'unit_tests' must be an object or omitted")
        else:
            if "enabled" in ut_cfg and not isinstance(ut_cfg["enabled"], bool):
                errors.append(f"{name}: project.json unit_tests.enabled must be boolean")
            if "expected_passing_count" in ut_cfg:
                n = ut_cfg["expected_passing_count"]
                if not isinstance(n, int) or n < 0:
                    errors.append(
                        f"{name}: project.json unit_tests.expected_passing_count "
                        f"must be a non-negative integer"
                    )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help="Repository root (default: parent of scripts/)",
    )
    args = parser.parse_args()
    root: Path = args.root.resolve()

    if not root.is_dir():
        print(f"error: --root is not a directory: {root}", file=sys.stderr)
        return 2

    all_errors: list[str] = []
    for d in _project_dirs(root):
        all_errors.extend(_validate_project(d))

    if all_errors:
        print("Project structure validation failed:\n", file=sys.stderr)
        for line in all_errors:
            print(f"  {line}", file=sys.stderr)
        return 1

    n = len(_project_dirs(root))
    print(f"OK: validated {n} project director{'y' if n == 1 else 'ies'} under {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
