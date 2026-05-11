#!/bin/bash
# libredwg: autotools. build.sh runs autogen + configure + make and
# `make check-prep -C test/unit-testing/`. Their `unit_testing_all.sh`
# orchestrates the C unit tests.
set -uo pipefail
cd /src/libredwg || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if [ ! -f Makefile ]; then
    sh ./autogen.sh >/tmp/lrd_autogen.log 2>&1 || true
    ./configure --disable-shared --disable-bindings --enable-release >/tmp/lrd_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -80 /tmp/lrd_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

make -j"$(nproc)" >/tmp/lrd_make.log 2>&1 || {
    echo "=== make failed ==="; tail -120 /tmp/lrd_make.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

# Run the upstream test runner. It emits autotools-style "# PASS:" /
# "# FAIL:" lines plus a final summary. The runner echoes DWG sample bytes
# into stdout, which would otherwise poison the harness's text-mode capture
# with non-UTF8 — strip non-printable bytes before forwarding.
out=$(mktemp)
make check -C test/unit-testing -j"$(nproc)" >"$out" 2>&1 || true
# Filter to printable + whitespace bytes; emit a sanitised view for the parser.
LC_ALL=C tr -cd '\11\12\15\40-\176' <"$out" >/tmp/libredwg_test_clean.log
cat /tmp/libredwg_test_clean.log

# libredwg's runner ends with "All N tests passed" / "FAILURE: N tests failed".
# Normalize into the "N passed, M failed" form the generic parser expects.
python3 - /tmp/libredwg_test_clean.log <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m_all = re.search(r"All (\d+) tests passed", text)
m_fail = re.search(r"FAILURE:\s*(\d+) tests? failed", text)
m_some = re.search(r"(\d+) of (\d+) tests passed", text)
if m_all:
    print(f"{int(m_all.group(1))} passed, 0 failed")
elif m_some:
    p, t = int(m_some.group(1)), int(m_some.group(2))
    print(f"{p} passed, {t-p} failed")
else:
    p = sum(int(x) for x in re.findall(r"# PASS:\s*(\d+)", text))
    f = sum(int(x) for x in re.findall(r"# FAIL:\s*(\d+)", text))
    if not p and not f:
        # Fallback: count individual PASS:/FAIL: result lines.
        p = sum(1 for _ in re.finditer(r"^PASS:", text, re.MULTILINE))
        f = sum(1 for _ in re.finditer(r"^FAIL:", text, re.MULTILINE))
    print(f"{p} passed, {f} failed")
PY

