#!/bin/bash
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cd /src/pytz
pip3 install -q pytest >/dev/null 2>&1 || true
python3 -m pytest src/pytz/tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest