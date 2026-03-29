#!/bin/bash
set -euo pipefail
cd /src/coveragepy
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest -c /dev/null tests/test_misc.py -q --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest