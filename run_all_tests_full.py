#!/usr/bin/env python3
"""Run all project test.sh scripts in parallel and report failures/mismatches."""

import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

BASE_DIR = Path("/home/anl31/documents/code/vulinjector/vuljector-projects")
RESULTS_FILE = BASE_DIR / "full_test_results.txt"
MAX_WORKERS = 8
TIMEOUT = 900  # 15 minutes per test

def get_projects():
    projects = []
    for d in sorted(BASE_DIR.iterdir()):
        if not d.is_dir():
            continue
        project = d.name
        test_sh = d / "unit_tests" / "test.sh"
        project_json = d / "project.json"
        if not test_sh.exists() or not project_json.exists():
            continue
        try:
            data = json.loads(project_json.read_text())
            expected = data.get("unit_tests", {}).get("expected_passing_count")
            if expected is not None:
                projects.append((project, expected))
        except Exception:
            pass
    return projects

def image_exists(image_name):
    result = subprocess.run(
        ["docker", "image", "inspect", image_name],
        capture_output=True, timeout=10
    )
    return result.returncode == 0

def run_project(project, expected):
    image_name = f"vuljector-{project}"
    unit_tests_dir = BASE_DIR / project / "unit_tests"

    if not image_exists(image_name):
        return ("SKIP", project, f"no image", expected, "")

    try:
        result = subprocess.run(
            [
                "docker", "run", "--rm",
                "-v", f"{unit_tests_dir}:/src/unit_tests:ro",
                image_name,
                "bash", "/src/unit_tests/test.sh"
            ],
            capture_output=True, timeout=TIMEOUT
        )
        output = (result.stdout + result.stderr).decode("utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        return ("TIMEOUT", project, f"timed out after {TIMEOUT}s", expected, "")
    except Exception as e:
        return ("ERROR", project, str(e), expected, "")

    # Get last non-empty line
    lines = [l.strip() for l in output.strip().splitlines() if l.strip()]
    last_line = lines[-1] if lines else ""

    try:
        data = json.loads(last_line)
        actual_passed = data.get("passed", 0)
        actual_failed = data.get("failed", 0)
    except (json.JSONDecodeError, ValueError):
        return ("FAIL", project, f"invalid output: {last_line[:200]}", expected, last_line)

    has_failures = actual_failed > 0
    has_mismatch = actual_passed != expected
    too_few = actual_passed < 4

    if has_failures and has_mismatch:
        status = "FAIL+MISMATCH"
        detail = f"passed={actual_passed} failed={actual_failed} expected={expected}"
    elif has_failures:
        status = "FAIL"
        detail = f"passed={actual_passed} failed={actual_failed} expected={expected}"
    elif has_mismatch:
        status = "MISMATCH"
        detail = f"passed={actual_passed} expected={expected}"
    elif too_few:
        status = "TOO_FEW"
        detail = f"passed={actual_passed} expected={expected} (minimum 4 required)"
    else:
        status = "PASS"
        detail = f"passed={actual_passed}"

    return (status, project, detail, expected, last_line)

def main():
    projects = get_projects()
    print(f"Found {len(projects)} projects with tests", flush=True)
    print(f"Running with {MAX_WORKERS} parallel workers, {TIMEOUT}s timeout each...", flush=True)
    print("=" * 60, flush=True)

    results = []
    completed = 0

    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        futures = {executor.submit(run_project, p, e): (p, e) for p, e in projects}
        for future in as_completed(futures):
            completed += 1
            status, project, detail, expected, raw = future.result()
            print(f"[{completed}/{len(projects)}] {status}: {project} | {detail}", flush=True)
            results.append((status, project, detail, expected, raw))

    # Write results file
    with open(RESULTS_FILE, "w") as f:
        for status, project, detail, expected, raw in sorted(results, key=lambda x: x[1]):
            f.write(f"{status}|{project}|{detail}|{raw}\n")

    # Summary
    print("\n" + "=" * 60)
    print("SUMMARY")
    print("=" * 60)

    by_status = {}
    for status, project, detail, expected, raw in results:
        by_status.setdefault(status, []).append((project, detail))

    for status in ["PASS", "FAIL", "MISMATCH", "FAIL+MISMATCH", "TOO_FEW", "SKIP", "TIMEOUT", "ERROR"]:
        items = by_status.get(status, [])
        print(f"\n{status}: {len(items)}")
        if status != "PASS":
            for project, detail in sorted(items):
                print(f"  - {project}: {detail}")

    total = len(results)
    passed = len(by_status.get("PASS", []))
    print(f"\nTotal: {total} | Pass: {passed} | Issues: {total - passed}")
    print(f"\nResults saved to: {RESULTS_FILE}")

if __name__ == "__main__":
    main()
