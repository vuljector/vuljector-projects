#!/bin/bash
set -euo pipefail
cd /src/c-ares
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
./test/arestest 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gtest