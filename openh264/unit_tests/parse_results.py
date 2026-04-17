#!/usr/bin/env python3
"""Read test output from stdin, pass it through, append JSON summary line.

Supported frameworks:
  pytest, cargo, gotest, ctest, maven, gradle, jest, tap, mocha, jasmine,
  phptest, btest, gtest, meson, unittest, autotools, rspec, boost, exprtk,
  utscapy,
  generic
"""
import argparse, json, re, sys


# -- regex-based parsers (first-match on pos/neg patterns) ----------------
_REGEX_PARSERS = {
    "cargo":    (r"(\d+) passed",        r"(\d+) failed"),
    "jest":     (r"(\d+) passed",        r"(\d+) failed"),
    "gtest":    (r"\[\s*PASSED\s*\]\s*(\d+) tests?", r"\[\s*FAILED\s*\]\s*(\d+) tests?"),
    "unittest": (r"Ran (\d+) test",      r"failures=(\d+)"),
    # generic: same as pytest -- works for anything that prints "N passed, M failed"
    "generic":  (r"(\d+) passed",        r"(\d+) failed"),
}


def _sum(pattern: str, text: str) -> int:
    return sum(int(m) for m in re.findall(pattern, text, re.IGNORECASE))


def _parse_unittest(text: str) -> dict:
    """Python unittest: 'Ran 12 tests ... OK' or 'FAILED (failures=2, errors=1)'."""
    total = _sum(r"Ran (\d+) test", text)
    failures = _sum(r"failures=(\d+)", text)
    errors = _sum(r"errors=(\d+)", text)
    failed = failures + errors
    return {"passed": max(total - failed, 0), "failed": failed}


def _parse_pytest(text: str) -> dict:
    """Pytest summary: '2 failed, 1904 passed, 84 skipped'."""
    passed = failed = 0
    for line in reversed(text.splitlines()):
        if "passed" not in line and "failed" not in line:
            continue
        passed_match = re.search(r"(\d+)\s+passed", line)
        failed_match = re.search(r"(\d+)\s+failed", line)
        if passed_match or failed_match:
            passed = int(passed_match.group(1)) if passed_match else 0
            failed = int(failed_match.group(1)) if failed_match else 0
            return {"passed": passed, "failed": failed}
    return {"passed": 0, "failed": 0}


def _parse_gotest(text: str) -> dict:
    return {"passed": text.count("--- PASS:"), "failed": text.count("--- FAIL:")}


def _parse_gradle(text: str) -> dict:
    # "3 tests completed, 1 failed" -- match only lines containing "completed"
    total = _sum(r"(\d+) tests? completed", text)
    # Match "N failed" only on lines that also contain "completed" or in Gradle summary
    failed = 0
    for line in text.splitlines():
        if re.search(r"tests? completed", line, re.IGNORECASE):
            failed += _sum(r"(\d+) failed", line)
    return {"passed": max(total - failed, 0), "failed": failed}


def _parse_tap(text: str) -> dict:
    """TAP / Perl Test::Harness: 'Files=350, Tests=4531, ...' + 'Failed: N)'.
    Also handles Node.js TAP: '# pass N' / '# tests N' / '# fail N'."""
    total = _sum(r"Tests=(\d+)", text)
    failed = _sum(r"Failed:\s+(\d+)\)", text)
    if total == 0:
        # Node.js TAP (tape, tap, node-tap)
        total = _sum(r"# tests\s+(\d+)", text) or _sum(r"# pass\s+(\d+)", text)
        failed = _sum(r"# fail\s+(\d+)", text)
    return {"passed": max(total - failed, 0), "failed": failed}


def _parse_mocha(text: str) -> dict:
    """Mocha spec/min reporter: 'N passing' / 'N failing' / 'N pending'."""
    passed = _sum(r"(\d+) passing", text)
    failed = _sum(r"(\d+) failing", text)
    return {"passed": passed, "failed": failed}


def _parse_rspec(text: str) -> dict:
    """RSpec summary: '123 examples, 0 failures'."""
    m = re.search(r"(\d+) examples?,\s*(\d+) failures?", text, re.IGNORECASE)
    if m:
        total, failed = int(m.group(1)), int(m.group(2))
        return {"passed": max(total - failed, 0), "failed": failed}
    return {"passed": 0, "failed": 0}


def _parse_jasmine(text: str) -> dict:
    """Jasmine: 'N specs, M failures' or 'N specs, 0 failures'."""
    m = re.search(r"(\d+) specs?,\s*(\d+) failures?", text)
    if m:
        total, failed = int(m.group(1)), int(m.group(2))
        return {"passed": max(total - failed, 0), "failed": failed}
    # Also handle "Ran N of N specs" success format
    passed = _sum(r"(\d+) specs? executed", text)
    return {"passed": passed, "failed": 0}


def _parse_ctest(text: str) -> dict:
    """CTest summary: '0 tests failed out of 125' or '100% tests passed, 0 tests failed out of 125'."""
    m = re.search(r"(\d+) tests? failed out of (\d+)", text)
    if m:
        failed, total = int(m.group(1)), int(m.group(2))
        return {"passed": total - failed, "failed": failed}
    return {"passed": 0, "failed": 0}


def _parse_meson(text: str) -> dict:
    """Meson test summary: 'Ok:  12  Expected Fail: 0  Fail: 1  ...'."""
    passed = _sum(r"Ok:\s*(\d+)", text)
    failed = _sum(r"(?<!Expected )Fail:\s*(\d+)", text)
    return {"passed": passed, "failed": failed}


def _parse_maven(text: str) -> dict:
    """Maven Surefire: 'Tests run: 100, Failures: 2, Errors: 1, Skipped: 3'."""
    total = _sum(r"Tests run:\s*(\d+)", text)
    failures = _sum(r"Failures:\s*(\d+)", text)
    errors = _sum(r"Errors:\s*(\d+)", text)
    skipped = _sum(r"Skipped:\s*(\d+)", text)
    failed = failures + errors
    passed = max(total - failed - skipped, 0)
    return {"passed": passed, "failed": failed}


def _parse_phptest(text: str) -> dict:
    """PHP run-tests.php: 'Tests passed  :   816 ( 94.0%)'."""
    passed = _sum(r"Tests passed\s*:\s*(\d+)", text)
    failed = _sum(r"Tests failed\s*:\s*(\d+)", text)
    return {"passed": passed, "failed": failed}


def _parse_autotools(text: str) -> dict:
    """Autotools make check: '# PASS:  42' / '# FAIL:   0' / '# TOTAL: 42'."""
    passed = _sum(r"# PASS:\s*(\d+)", text)
    failed = _sum(r"# FAIL:\s*(\d+)", text)
    # Also handle "N of N tests passed" variant
    if passed == 0 and failed == 0:
        m = re.search(r"(\d+) of (\d+) tests? passed", text)
        if m:
            passed, total = int(m.group(1)), int(m.group(2))
            failed = total - passed
    if passed == 0 and failed == 0:
        m = re.search(r"All\s+(\d+)\s+tests?\s+PASSED", text, re.IGNORECASE)
        if m:
            passed = int(m.group(1))
    return {"passed": passed, "failed": failed}


def _parse_btest(text: str) -> dict:
    """Ruby btest: 'PASS all 2047 tests' or 'FAIL 3/2047 tests failed'."""
    m = re.search(r"PASS all (\d+) tests", text)
    if m:
        return {"passed": int(m.group(1)), "failed": 0}
    m = re.search(r"FAIL (\d+)/(\d+) tests? failed", text)
    if m:
        failed, total = int(m.group(1)), int(m.group(2))
        return {"passed": max(total - failed, 0), "failed": failed}
    return {"passed": 0, "failed": 0}


def _parse_boost(text: str) -> dict:
    """Boost.Test summary: 'Running 17 test cases...' + final error summary."""
    total = _sum(r"Running\s+(\d+)\s+test cases?", text)
    failed = _sum(r"\*\*\*\s+(\d+)\s+failures? detected", text)
    if re.search(r"\*\*\*\s+No errors detected", text):
        failed = 0
    if total == 0 and re.search(r"\*\*\*\s+No errors detected", text):
        total = 1
    return {"passed": max(total - failed, 0), "failed": failed}


def _parse_exprtk(text: str) -> dict:
    """ExprTk test summary.

    This test binary uses custom reporting, so support a few known summary forms
    and fall back to the generic parser shapes when possible.
    """
    patterns = (
        r"All\s+(\d+)\s+tests?\s+passed",
        r"(\d+)\s+tests?\s+passed",
        r"total\s+tests?\s*:\s*(\d+)",
    )
    failed_patterns = (
        r"(\d+)\s+tests?\s+failed",
        r"fail(?:ed|ures?)\s*:\s*(\d+)",
        r"errors?\s*:\s*(\d+)",
    )
    passed = 0
    failed = 0
    for pattern in patterns:
        passed = _sum(pattern, text)
        if passed:
            break
    for pattern in failed_patterns:
        failed += _sum(pattern, text)
    if passed == 0 and failed == 0:
        return _parse_mocha(text)
    if failed and passed and passed < failed:
        passed = 0
    return {"passed": max(passed - failed, 0) if "total" in text.lower() else passed, "failed": failed}


def _parse_utscapy(text: str) -> dict:
    """UTScapy campaign summary: 'PASSED=N FAILED=M' per loaded test file."""
    passed = _sum(r"PASSED=(\d+)", text)
    failed = _sum(r"FAILED=(\d+)", text)
    return {"passed": passed, "failed": failed}


# -- dispatch ----------------------------------------------------------------
_SPECIAL_PARSERS = {
    "gotest":   _parse_gotest,
    "pytest":   _parse_pytest,
    "gradle":   _parse_gradle,
    "tap":      _parse_tap,
    "mocha":    _parse_mocha,
    "rspec":    _parse_rspec,
    "jasmine":  _parse_jasmine,
    "ctest":    _parse_ctest,
    "meson":    _parse_meson,
    "maven":    _parse_maven,
    "phptest":  _parse_phptest,
    "btest":    _parse_btest,
    "boost":    _parse_boost,
    "exprtk":   _parse_exprtk,
    "utscapy":  _parse_utscapy,
    "unittest": _parse_unittest,
    "autotools": _parse_autotools,
}


def parse(text: str, framework: str) -> dict:
    """Parse test output and return {"passed": N, "failed": M}."""
    if framework in _SPECIAL_PARSERS:
        return _SPECIAL_PARSERS[framework](text)
    pos, neg = _REGEX_PARSERS.get(framework, _REGEX_PARSERS["generic"])
    return {"passed": _sum(pos, text), "failed": _sum(neg, text)}


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--framework", default="generic",
                   help="Test framework output format (unknown values fall back to generic)")
    args = p.parse_args()
    framework = args.framework if args.framework in set(_SPECIAL_PARSERS) | set(_REGEX_PARSERS) else "generic"
    text = sys.stdin.read()
    sys.stdout.write(text)
    if text and not text.endswith("\n"):
        sys.stdout.write("\n")
    print(json.dumps(parse(text, framework)))
