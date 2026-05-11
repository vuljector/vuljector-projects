#!/bin/bash
set -uo pipefail
cd /src/flac
cat >/tmp/flac_alloc_check_stub.c <<'EOF'
#include <stdint.h>
int alloc_check_threshold = INT32_MAX;
int alloc_check_counter = 0;
int alloc_check_keep_failing = 0;
EOF

gcc -c /tmp/flac_alloc_check_stub.c -o /tmp/flac_alloc_check_stub.o || {
    echo "=== gcc stub compile failed ==="
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

make -C src/test_libFLAC test_libFLAC -j"$(nproc)" \
  test_libFLAC_LDADD="$(pwd)/src/share/grabbag/libgrabbag.la $(pwd)/src/share/replaygain_analysis/libreplaygain_analysis.la $(pwd)/src/test_libs_common/libtest_libs_common.la $(pwd)/src/libFLAC/libFLAC-static.la /tmp/flac_alloc_check_stub.o /src/libogg-install/lib/libogg.a -lm" \
  >/tmp/flac_make.log 2>&1 || {
    echo "=== make test_libFLAC failed ==="
    tail -80 /tmp/flac_make.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

out=$(./src/test_libFLAC/test_libFLAC 2>&1)
test_rc=$?
passed=$(printf "%s" "$out" | grep -c '^PASSED!$' || true)
failed=$(printf "%s" "$out" | grep -c '^FAILED!$' || true)

# If the test binary crashed before producing any PASSED!/FAILED! lines,
# surface its tail so the agent (and the human auditor) can see WHY there
# are zero results — the empty pipe alone is uninformative.
if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
    echo "=== test_libFLAC produced no PASSED!/FAILED! lines (rc=$test_rc) ==="
    printf "%s" "$out" | tail -80
    echo "==================================================================="
fi

printf '%s\n' "# PASS: ${passed}" "# FAIL: ${failed}" "# TOTAL: $((passed + failed))" | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
