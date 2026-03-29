#!/bin/bash
set -euo pipefail
cd /src/python-bigquery
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
py.test tests/unit -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest