#!/bin/bash
set -e
cd /src/dateutil
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
export PYTHONPATH=/src/dateutil/src
python3 -W ignore -W ignore::pytest.PytestUnknownMarkWarning -m pytest tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest