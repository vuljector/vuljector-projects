#!/bin/bash
set -euo pipefail
cd /src/open62541
# Clear sanitizer flags (OSS-Fuzz quirk)
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

OUT=/tmp/test_output.txt
rm -f "$OUT"

# Run python-based unit/integration tests (do not run fuzz targets)
# Capture stdout/stderr
python3 tests/nodeset-compiler/test_cross_ns_types.py > "$OUT" 2>&1 || true
python3 tests/nodeset-compiler/test_splitNodeidNs.py >> "$OUT" 2>&1 || true

# Derive a simple summary line that the parser can understand (e.g. "15 passed, 0 failed")
# Count explicit "PASS:" lines and "All N tests passed." summaries from the test outputs
PASSED_FROM_PASS_LINES=$(grep -c "^PASS:" "$OUT" || true)
PASSED_FROM_SUMMARY=$(sed -n '1,120p' "$OUT" | grep -oE "All [0-9]+ tests passed\.?" -o | sed -n 's/All \([0-9]\+\) tests passed\.?/\1/p' || true)
# The above sed invocation may produce multiple lines; sum them
SUM_PASSED_SUMMARY=0
if [ -n "${PASSED_FROM_SUMMARY:-}" ]; then
  while read -r n; do
    [ -z "$n" ] && continue
    SUM_PASSED_SUMMARY=$((SUM_PASSED_SUMMARY + n))
  done <<<"$PASSED_FROM_SUMMARY"
fi
TOTAL_PASSED=$((PASSED_FROM_PASS_LINES + SUM_PASSED_SUMMARY))

# Fallback: if we found no passes but tests printed "All N tests passed." without preceding PASS: lines
if [ "$TOTAL_PASSED" -eq 0 ]; then
  # try to capture any "All N tests passed." elsewhere in the file
  N=$(grep -oE "All [0-9]+ tests passed\.?" "$OUT" | sed -n 's/All \([0-9]\+\) tests passed\.?/\1/p' | awk '{s+=($1)} END{print s+0}') || true
  if [ -n "$N" ] && [ "$N" -gt 0 ]; then
    TOTAL_PASSED=$N
  fi
fi

# Default failed to 0 unless we see FAIL markers
TOTAL_FAILED=$(grep -c "\bFAIL\b" "$OUT" || true)
# Normalize empty to 0
TOTAL_PASSED=${TOTAL_PASSED:-0}
TOTAL_FAILED=${TOTAL_FAILED:-0}

# Append a summary line that the generic parser will detect
echo "${TOTAL_PASSED} passed, ${TOTAL_FAILED} failed" >> "$OUT"

# Finally, stream the collected output through the OSS-Fuzz result parser
cat "$OUT" 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic