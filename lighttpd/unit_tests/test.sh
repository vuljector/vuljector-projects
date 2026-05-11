#!/bin/bash
# lighttpd: autotools (also has cmake/meson). OSS-Fuzz run_tests.sh just runs
# `make check`, which builds and runs src/t/test_* unit-test binaries.
set -uo pipefail
cd /src/lighttpd1.4 || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if [ ! -f Makefile ]; then
    ./autogen.sh >/tmp/lighttpd_autogen.log 2>&1 || true
    ./configure --without-pcre --enable-static >/tmp/lighttpd_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -50 /tmp/lighttpd_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

make -j"$(nproc)" >/tmp/lighttpd_make.log 2>&1 || {
    echo "=== make failed ==="; tail -120 /tmp/lighttpd_make.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

out=$(mktemp)
make check >"$out" 2>&1 || true
cat "$out"

# run-tests.pl drives the Perl Test::Harness, which emits a "Files=N,
# Tests=M, Failed=K" footer. The outer autotools shim only counts the 3
# script invocations (prepare/run-tests/cleanup), so dig out the inner
# Test::Harness numbers instead.
python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
m_total = re.search(r"Files=\d+,\s*Tests=(\d+)", text)
m_fail  = re.search(r"Failed=(\d+)", text)
if m_total:
    total = int(m_total.group(1))
    failed = int(m_fail.group(1)) if m_fail else 0
    # If we don't see "Result: PASS", assume the run aborted before TAP
    # could finish and treat as fully failed.
    if "Result: PASS" not in text and failed == 0 and total > 0:
        failed = total
    print(f"{max(total - failed, 0)} passed, {failed} failed")
else:
    # Pre-test setup may have failed before run-tests.pl ran.
    p = sum(int(x) for x in re.findall(r"# PASS:\s*(\d+)", text))
    f = sum(int(x) for x in re.findall(r"# FAIL:\s*(\d+)", text))
    print(f"{p} passed, {f} failed")
PY
