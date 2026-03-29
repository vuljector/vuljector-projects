#!/bin/bash
cd /src/jansson || exit 1
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
./configure || exit 1
make -j$(nproc) || exit 1
make check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
SCRIPT_EOF && chmod +x /tmp/test_harness.sh