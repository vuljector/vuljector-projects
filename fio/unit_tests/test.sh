#!/bin/bash
set -euo pipefail
cd /src/fio
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
./unittests/unittest 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest