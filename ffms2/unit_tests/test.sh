#!/bin/bash
set -euo pipefail
cd /src/ffms2
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
./configure
make -j$(nproc)
cd test
make run 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gtest