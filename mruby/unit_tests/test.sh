#!/bin/bash
set -euo pipefail
cd /src/mruby
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
out=$(mktemp)
rake test:run:serial 2>&1 | tee "$out" | python3 /workspace/run/unit_tests/parse_results.py --framework autotools >/dev/null
passed=$(grep -E '^\s*OK:' "$out" | awk '{sum+=$2} END{print sum+0}')
failed=$(awk '/^\s*KO:|^\s*Crash:/{sum+=$2} END{print sum+0}' "$out")
if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
  passed=$(grep -E '^\s*Total:' "$out" | awk '{print $2+0}')
fi
rm -f "$out"
printf '{"passed": %s, "failed": %s}\n' "$passed" "$failed"