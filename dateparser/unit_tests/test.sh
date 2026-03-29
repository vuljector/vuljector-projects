#!/bin/bash
set -e
cd /src/dateparser
pip3 install -q pytest parameterized >/dev/null 2>&1 || true
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest tests/test_utils.py -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest