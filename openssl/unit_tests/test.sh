#!/bin/bash
set -euo pipefail
cd /src/openssl
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
./config >/dev/null
make -j"$(nproc)" >/dev/null
make TESTS="test_sanity test_sha test_dgst test_rand test_aesgcm" test HARNESS_JOBS="$(nproc)" 2>&1 \
  | python3 /workspace/run/unit_tests/parse_results.py --framework tap
