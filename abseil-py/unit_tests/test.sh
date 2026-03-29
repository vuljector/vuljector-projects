#!/bin/bash
set -euo pipefail
cd /src/abseil-py
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 smoke_tests/sample_test.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest