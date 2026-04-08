#!/bin/bash
set -euo pipefail
cd /src/tinyobjloader/tests
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make clean >/dev/null 2>&1 || true
make tester -j"$(nproc)" >/dev/null
out=$(./tester 2>&1 || true)
printf '%s\n' "$out"
passed=$(printf '%s\n' "$out" | grep -c '\[ OK \]' || true)
failed=$(printf '%s\n' "$out" | grep -c '\[ FAILED \]' || true)
printf '# PASS: %s\n# FAIL: %s\n' "$passed" "$failed" | python3 /workspace/run/unit_tests/parse_results.py --framework autotools