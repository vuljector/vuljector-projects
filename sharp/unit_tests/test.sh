#!/bin/bash
set -euo pipefail
cd /src/sharp
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
out=$(node --test --test-reporter=tap $(find test/unit -maxdepth 1 -name '*.js' | sort) 2>&1 || true)
echo "$out"
passed=$(printf '%s\n' "$out" | grep -E '^ok [0-9]+ - ' | wc -l | tr -d ' ')
failed=$(printf '%s\n' "$out" | grep -E '^not ok [0-9]+ - ' | wc -l | tr -d ' ')
echo "$passed passed, $failed failed" | python3 /workspace/run/unit_tests/parse_results.py --framework generic