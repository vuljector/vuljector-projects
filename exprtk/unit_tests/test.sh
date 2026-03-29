#!/bin/bash
set -euo pipefail
cd /src/exprtk
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make exprtk_test
./exprtk_test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework exprtk