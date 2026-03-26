#!/usr/bin/env python3
"""Minimal checker for project unit test baseline counts.

For each project under vuljector-projects:
- build image from setup/
- in the container: run OSS-Fuzz /src/build.sh (same pattern as Vuljector run_setup test-discovery:
  bash /src/build.sh 2>&1 | tail -30 || true), then unit_tests/test.sh from /src/<target_dir>.
- parse passing test count (including parse_results.py JSON summary)
- compare to project.json unit_tests.expected_passing_count

By default a copy of the script output is written to check_expected_passing_tests.log
(next to this file). Use --no-log-file or --log PATH to change behavior.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator, TextIO


PASSING_RE = re.compile(r"PASSING_TESTS\s*=\s*(\d+)")
PYTEST_RE = re.compile(r"(\d+)\s+passed")


@contextmanager
def open_log(path: Path | None) -> Iterator[TextIO | None]:
    if path is None:
        yield None
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as fp:
        yield fp


def emit(msg: str, *, log_fp: TextIO | None) -> None:
    print(msg)
    if log_fp is not None:
        log_fp.write(msg + "\n")
        log_fp.flush()


def run_cmd(args: list[str], *, timeout: int | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=timeout)


def parse_passing_count(output: str) -> int | None:
    # parse_results.py appends a JSON summary as the last line: {"passed": N, "failed": M}
    for line in reversed(output.strip().splitlines()):
        line = line.strip()
        if line.startswith("{") and '"passed"' in line:
            try:
                data = json.loads(line)
                if "passed" in data:
                    return int(data["passed"])
            except (json.JSONDecodeError, ValueError, TypeError):
                pass
    match = PASSING_RE.search(output)
    if match:
        return int(match.group(1))
    match = PYTEST_RE.search(output)
    if match:
        return int(match.group(1))
    return None


def iter_projects(root: Path, only: set[str] | None) -> list[Path]:
    projects: list[Path] = []
    for cfg in sorted(root.glob("*/project.json")):
        project_dir = cfg.parent
        if only and project_dir.name not in only:
            continue
        projects.append(project_dir)
    return projects


def build_image(project: str, setup_dir: Path, rebuild: bool) -> tuple[bool, str]:
    tag = f"vuljector/{project}:baseline-check"
    if not rebuild:
        inspect = run_cmd(["docker", "image", "inspect", tag])
        if inspect.returncode == 0:
            return True, tag

    res = run_cmd(["docker", "build", "-t", tag, str(setup_dir)])
    ok = res.returncode == 0
    out = (res.stderr or res.stdout).strip()
    return ok, out if not ok else tag


def expected_count_from_cfg(project_dir: Path, cfg: dict) -> int | None:
    project = str(cfg.get("project") or project_dir.name)
    unit_tests = cfg.get("unit_tests") or {}
    if not unit_tests.get("enabled"):
        return None
    expected = unit_tests.get("expected_passing_count")
    if expected is None:
        return None
    return int(expected)


def run_project_tests(project_dir: Path, cfg: dict, image_tag: str, timeout_s: int) -> tuple[str, int | None, str]:
    project = str(cfg.get("project") or project_dir.name)
    target_dir = str(cfg.get("target_dir") or project)
    unit_tests = cfg.get("unit_tests") or {}
    expected = unit_tests.get("expected_passing_count")

    if not unit_tests.get("enabled"):
        return "SKIP", None, "unit_tests.disabled"
    if expected is None:
        return "SKIP", None, "unit_tests.expected_passing_count missing"

    test_sh = project_dir / "unit_tests" / "test.sh"
    if not test_sh.exists():
        return "FAIL", None, "unit_tests/test.sh missing"

    # Match vuljector run_injection.py: mount unit_tests/ at /workspace/run/unit_tests/
    cmd = (
        f"bash /src/build.sh 2>&1 | tail -30 || true; "
        f"cd /src/{target_dir} && "
        f"bash /workspace/run/unit_tests/test.sh"
    )
    res = run_cmd(
        [
            "docker",
            "run",
            "--rm",
            "-v",
            f"{project_dir / 'unit_tests'}:/workspace/run/unit_tests:ro",
            image_tag,
            "bash",
            "-lc",
            cmd,
        ],
        timeout=timeout_s,
    )

    output = (res.stdout or "") + "\n" + (res.stderr or "")
    passed = parse_passing_count(output)
    if passed is None:
        tail = output.strip().splitlines()[-30:]
        detail = "\n".join(tail)
        return "FAIL", None, f"could not parse passing count (exit={res.returncode})\n--- tail ---\n{detail}\n--- end ---"

    if int(passed) == int(expected):
        return "PASS", passed, f"matches expected={expected}"
    return "FAIL", passed, f"expected={expected}, got={passed}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Check expected passing test counts per project.")
    parser.add_argument(
        "--projects",
        nargs="*",
        default=None,
        help="Optional project names to check (default: all).",
    )
    parser.add_argument(
        "--rebuild",
        action="store_true",
        help="Force docker rebuild even if image tag exists.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=900,
        help="Per-project test timeout in seconds (default: 900).",
    )
    parser.add_argument(
        "--log",
        type=Path,
        default=None,
        metavar="FILE",
        help="Write a copy of this script's output to FILE "
        f"(default: <vuljector-projects>/check_expected_passing_tests.log).",
    )
    parser.add_argument(
        "--no-log-file",
        action="store_true",
        help="Do not write a log file (stdout only).",
    )
    args = parser.parse_args()

    root = Path(__file__).resolve().parent
    log_path: Path | None = None
    if not args.no_log_file:
        log_path = args.log if args.log is not None else root / "check_expected_passing_tests.log"

    with open_log(log_path) as log_fp:
        def say(msg: str = "") -> None:
            emit(msg, log_fp=log_fp)

        if log_path is not None:
            say(f"# check_expected_passing_tests.log started {datetime.now(timezone.utc).isoformat()}")

        selected = set(args.projects) if args.projects else None
        project_dirs = iter_projects(root, selected)
        if not project_dirs:
            say("No matching projects found.")
            return 1

        failed = 0
        skipped = 0
        passed = 0

        total = len(project_dirs)
        for idx, project_dir in enumerate(project_dirs, start=1):
            project = project_dir.name
            say(f"\n[{idx}/{total}] {project}")
            cfg_path = project_dir / "project.json"
            try:
                cfg = json.loads(cfg_path.read_text(encoding="utf-8"))
            except Exception as exc:
                failed += 1
                say(f"[FAIL] {project}: invalid project.json ({exc})")
                continue

            setup_dir = project_dir / "setup"
            if not setup_dir.exists():
                failed += 1
                say(f"[FAIL] {project}: setup/ missing")
                continue

            expected = expected_count_from_cfg(project_dir, cfg)
            if expected is None:
                say(f"  - expected passing count: n/a")
            else:
                say(f"  - expected passing count: {expected}")

            say("  - build image...")
            build_ok, build_info = build_image(project, setup_dir, args.rebuild)
            if not build_ok:
                failed += 1
                say(f"[FAIL] {project}: docker build failed")
                say(f"       {build_info[:400]}")
                continue
            say("  - image ready")

            try:
                say("  - run /src/build.sh then unit_tests/test.sh ...")
                status, count, msg = run_project_tests(project_dir, cfg, str(build_info), args.timeout)
            except subprocess.TimeoutExpired:
                failed += 1
                say(f"[FAIL] {project}: test timed out after {args.timeout}s")
                continue
            except Exception as exc:
                failed += 1
                say(f"[FAIL] {project}: test run error ({exc})")
                continue

            if count is not None:
                say(f"  - parsed passing count: {count}")

            if status == "PASS":
                passed += 1
                say(f"[PASS] {project}: {count} passed ({msg})")
            elif status == "SKIP":
                skipped += 1
                say(f"[SKIP] {project}: {msg}")
            else:
                failed += 1
                if count is None:
                    say(f"[FAIL] {project}: {msg}")
                else:
                    say(f"[FAIL] {project}: {msg}")

        say(f"\nDone. passed={passed} failed={failed} skipped={skipped}")
        if log_path is not None:
            say(f"# log file: {log_path.resolve()}")
        return 0 if failed == 0 else 2


if __name__ == "__main__":
    sys.exit(main())
