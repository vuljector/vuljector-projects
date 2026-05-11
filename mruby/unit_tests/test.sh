#!/bin/bash
set -uo pipefail
cd /src/mruby
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
out=$(mktemp)
rake test:run:serial 2>&1 | tee "$out" | python3 /workspace/run/unit_tests/parse_results.py --framework autotools >/dev/null || true
passed=$(grep -E '^\s*OK:' "$out" | awk '{sum+=$2} END{print sum+0}')
failed=$(awk '/^\s*KO:|^\s*Crash:/{sum+=$2} END{print sum+0}' "$out")
if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
  passed=$(grep -E '^\s*Total:' "$out" | awk '{print $2+0}')
fi
# If both still 0, the rake step crashed before printing any result lines.
# Surface the tail of rake's output so the agent sees the actual error
# rather than a silent {"passed": 0} the verifier can't explain.
if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
  echo "=== rake produced no recognisable test results — tail of output ==="
  tail -80 "$out"
  echo "==================================================================="
fi
rm -f "$out"
printf '{"passed": %s, "failed": %s}\n' "$passed" "$failed"