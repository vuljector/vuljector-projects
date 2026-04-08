#!/bin/bash
set -e
cd /src/croniter
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 show pytest >/dev/null 2>&1 || pip3 install -q pytest
pip3 show pytz >/dev/null 2>&1 || pip3 install -q pytz
python3 -m pytest src/croniter/tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest