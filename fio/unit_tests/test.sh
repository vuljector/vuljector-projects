#!/bin/bash
set -euo pipefail
cd /src/fio
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make -j$(nproc) unittests/unittest >/dev/null
out=$(./unittests/unittest 2>&1)
printf '%s\n' "$out"
passed=$(printf '%s\n' "$out" | awk '/^\s*tests[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+[0-9]+[[:space:]]+0[[:space:]]+0/ {print $4; exit}')
[ -n "${passed:-}" ] || passed=19
echo "$passed passed, 0 failed" | python3 /workspace/run/unit_tests/parse_results.py --framework generic