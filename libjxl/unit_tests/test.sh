#!/bin/bash
set -euo pipefail
cd /src/libjxl
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

passed=0
failed=0

if ./bash_test.sh > /tmp/libjxl_bash_test.out 2>&1; then
  :
else
  true
fi

passed=$(grep -c ': PASS$' /tmp/libjxl_bash_test.out || true)
failed=$(grep -c ': FAIL$' /tmp/libjxl_bash_test.out || true)

cat /tmp/libjxl_bash_test.out
printf '%s passed, %s failed\n' "$passed" "$failed" | python3 /workspace/run/unit_tests/parse_results.py --framework generic
