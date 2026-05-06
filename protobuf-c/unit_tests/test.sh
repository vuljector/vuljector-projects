#!/bin/bash
set -euo pipefail
cd /src/protobuf-c
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make distclean >/dev/null 2>&1 || true
autoreconf -fi >/dev/null 2>&1
./configure >/dev/null 2>&1
make -j4 >/dev/null
make check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
