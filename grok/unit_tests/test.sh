#!/bin/bash
set -euo pipefail
cd /src/grok
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
export PYTHONUNBUFFERED=1
export PYTHONPATH="/workspace/run/unit_tests:${PYTHONPATH:-}"

# Full suite ~3–4 minutes; capture to a file so the parser always sees the full
# summary line (avoids pipe edge cases) and matches reliably under load.
log=$(mktemp)
trap 'rm -f "$log"' EXIT

set +e
python3 /workspace/run/unit_tests/run_tests.py >"$log" 2>&1
rc=$?
set -e

cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework generic <"$log"
exit "$rc"
