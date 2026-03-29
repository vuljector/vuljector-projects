#!/bin/bash
set -euo pipefail
cd /src/njs
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
set +e
make -j$(nproc) test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic | tee /tmp/njs_test_out.txt
rc=${PIPESTATUS[0]}
set -e
passed=$(grep -oE 'PASSED \[[0-9]+/[0-9]+\]' /tmp/njs_test_out.txt | sed -E 's/.*\[([0-9]+)\/([0-9]+)\].*/\1/' | awk '{s+=$1} END{print s+0}')
failed=$(grep -oE 'FAILED \[[0-9]+/[0-9]+\]' /tmp/njs_test_out.txt | sed -E 's/.*\[([0-9]+)\/([0-9]+)\].*/\1/' | awk '{s+=$1} END{print s+0}')
echo "{\"passed\": ${passed:-0}, \"failed\": ${failed:-0}}"
exit 0