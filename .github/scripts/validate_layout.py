#!/usr/bin/env python3
"""Validate vuljector-projects layout against Vuljector expectations.

See Vuljector: setup/setup_test_harness/layout.py (validate_unit_tests_dir) and
vuljector-projects/README.md.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

# Must match setup/setup_test_harness/layout.py PARSER_PATH
PARSER_PATH = "/workspace/run/unit_tests/parse_results.py"

ROOT_DIR_SKIP = frozenset({"__pycache__", "z_analyze_projects"})
COMMIT_SHA_RE = re.compile(r"^[0-9a-f]{40}$", re.IGNORECASE)


def _repo_root() -> Path:
    """This file lives at .github/scripts/validate_layout.py."""
    return Path(__file__).resolve().parents[2]


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


def _project_dirs_from_git_diff(root: Path, git_range: str) -> list[Path]:
    """Top-level project directories that have any file changed in `git diff RANGE`."""
    result = subprocess.run(
        ["git", "-C", str(root), "diff", "--name-only", git_range],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        msg = (result.stderr or result.stdout or "").strip()
        raise RuntimeError(f"git diff failed ({git_range}): {msg}")

    touched: set[str] = set()
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line or "/" not in line:
            continue
        first = line.split("/", 1)[0]
        if first.startswith(".") or first in ROOT_DIR_SKIP:
            continue
        touched.add(first)

    out: list[Path] = []
    for name in sorted(touched):
        d = root / name
        if not d.is_dir():
            continue
        out.append(d)
    return out


def _validate_project(project_dir: Path) -> list[str]:
    errors: list[str] = []
    name = project_dir.name

    def rel(p: Path) -> str:
        return str(p.relative_to(project_dir.parent))

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
                if isinstance(n, bool) or not isinstance(n, int) or n < 0:
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
        default=_repo_root(),
        help="Repository root (default: parent of .github/)",
    )
    parser.add_argument(
        "--git-range",
        metavar="REVISION_RANGE",
        help=(
            "Only validate top-level project dirs touched by `git diff REVISION_RANGE` "
            "(e.g. origin/main...HEAD for PRs). Requires a git checkout."
        ),
    )
    args = parser.parse_args()
    root: Path = args.root.resolve()

    if not root.is_dir():
        print(f"error: --root is not a directory: {root}", file=sys.stderr)
        return 2

    if args.git_range:
        try:
            to_check = _project_dirs_from_git_diff(root, args.git_range)
        except RuntimeError as exc:
            print(f"error: {exc}", file=sys.stderr)
            return 2
    else:
        to_check = _project_dirs(root)

    all_errors: list[str] = []
    for d in to_check:
        all_errors.extend(_validate_project(d))

    if all_errors:
        print("Project structure validation failed:\n", file=sys.stderr)
        for line in all_errors:
            print(f"  {line}", file=sys.stderr)
        return 1

    n = len(to_check)
    kind = "touched " if args.git_range else ""
    print(f"OK: validated {n} {kind}project director{'y' if n == 1 else 'ies'} under {root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
