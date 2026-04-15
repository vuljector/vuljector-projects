#!/bin/bash
set -euo pipefail
cd /src/flac
cat >/tmp/flac_alloc_check_stub.c <<'EOF'
#include <stdint.h>
int alloc_check_threshold = INT32_MAX;
int alloc_check_counter = 0;
int alloc_check_keep_failing = 0;
EOF

gcc -c /tmp/flac_alloc_check_stub.c -o /tmp/flac_alloc_check_stub.o
make -C src/test_libFLAC test_libFLAC -j"$(nproc)" \
  test_libFLAC_LDADD="$(pwd)/src/share/grabbag/libgrabbag.la $(pwd)/src/share/replaygain_analysis/libreplaygain_analysis.la $(pwd)/src/test_libs_common/libtest_libs_common.la $(pwd)/src/libFLAC/libFLAC-static.la /tmp/flac_alloc_check_stub.o /src/libogg-install/lib/libogg.a -lm"

set +e
out=$(./src/test_libFLAC/test_libFLAC 2>&1)
set -e
passed=$(printf "%s" "$out" | grep -c '^PASSED!$' || true)
failed=$(printf "%s" "$out" | grep -c '^FAILED!$' || true)
printf '%s\n' "# PASS: ${passed}" "# FAIL: ${failed}" "# TOTAL: $((passed + failed))" | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
