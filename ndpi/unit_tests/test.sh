#!/bin/bash
set -euo pipefail

# OSS-Fuzz already built /src/ndpi (including tests/unit/unit). Do not re-run
# configure in a fresh dir — the source tree is "already configured" and that
# path exits before any JSON summary is emitted.

cd /src/ndpi
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

UNIT_BIN=/src/ndpi/tests/unit/unit
if [ ! -x "$UNIT_BIN" ]; then
  echo "Unit test binary not found: $UNIT_BIN" >&2
  printf '%s\n' "0 passed, 1 failed" | python3 /workspace/run/unit_tests/parse_results.py --framework generic
  exit 1
fi

log=$(mktemp)
trap 'rm -f "$log"' EXIT

set +e
"$UNIT_BIN" >"$log" 2>&1
rc=$?
set -e

# nDPI prints one line per check ending in "OK" or "FAIL" (see tests/unit).
ok=$(grep -cE '[[:space:]]OK[[:space:]]*$' "$log" || true)
fail=$(grep -cE '[[:space:]]FAIL[[:space:]]*$' "$log" || true)
if [ "$rc" != 0 ] && [ "$fail" -eq 0 ]; then
  fail=1
fi

cat "$log"
printf '%s\n' "${ok} passed, ${fail} failed" | python3 /workspace/run/unit_tests/parse_results.py --framework generic
exit "$rc"
