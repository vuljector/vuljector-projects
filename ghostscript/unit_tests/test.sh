#!/bin/bash
set -uo pipefail

# Clear OSS-Fuzz sanitizer env vars which break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

cd /src/ghostpdl/jbig2dec

PASS=0
FAIL=0

run_test() {
    local name="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name"
        FAIL=$((FAIL + 1))
    fi
}

# T1: Python harness parses successfully.
run_test "py_compile test_jbig2dec.py" python3 -m py_compile test_jbig2dec.py

# T2: Native jbig2dec tool builds with the project's unix makefile.
run_test "build jbig2dec" make -f Makefile.unix -j"$(nproc)"

# T3: Built binary starts and returns a standard usage/version-style response.
run_test "run jbig2dec --help" bash -c "./jbig2dec --help >/dev/null 2>&1 || ./jbig2dec -h >/dev/null 2>&1"

# T4: SHA-1 unit test (self-contained, only depends on sha1.c).
run_test "build and run test_sha1" bash -c "gcc -DTEST -I. sha1.c -o test_sha1 2>/dev/null && ./test_sha1 2>/dev/null"

# T5: Decode the bundled annex-h.jbig2 conformance file without error.
run_test "decode annex-h.jbig2" ./jbig2dec -o /dev/null annex-h.jbig2

# T6: Decoded output hash of annex-h.jbig2 matches the known-good value.
run_test "annex-h.jbig2 hash" bash -c "
    got=\$(./jbig2dec -q -o /dev/null --hash annex-h.jbig2 2>/dev/null | grep -oE '[0-9a-f]{40}')
    [ \"\$got\" = '0f02dd30c038e397a2ed1e8d0d0dcbdbb4b94ff7' ]
"

{ echo "$PASS passed"; echo "$FAIL failed"; } | python3 /workspace/run/unit_tests/parse_results.py --framework generic