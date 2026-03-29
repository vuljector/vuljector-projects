#!/bin/bash
set -euo pipefail
cd /src/expat/build
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
ctest --output-on-failure -j$(nproc) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest