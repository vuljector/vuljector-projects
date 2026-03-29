#!/bin/bash
set -euo pipefail
cd /src/unicorn
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cd build
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest