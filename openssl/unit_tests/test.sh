#!/bin/bash
set -uo pipefail
cd /src/openssl
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""

./config >/tmp/openssl_config.log 2>&1 || {
    echo "=== ./config failed ==="
    tail -50 /tmp/openssl_config.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

make -j"$(nproc)" >/tmp/openssl_make.log 2>&1 || {
    echo "=== make -j (library build) failed ==="
    tail -80 /tmp/openssl_make.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

make TESTS="test_sanity test_sha test_dgst test_rand test_aesgcm" test HARNESS_JOBS="$(nproc)" 2>&1 \
  | python3 /workspace/run/unit_tests/parse_results.py --framework tap
