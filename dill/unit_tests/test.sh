#!/bin/bash
set -euo pipefail
cd /src/dill

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

python3 run_dill_tests.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic