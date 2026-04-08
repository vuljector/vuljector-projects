#!/bin/bash
set -e
cd /src/dateutil
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
export PYTHONPATH=/src/dateutil/src
python3 -m pytest tests/test_easter.py tests/test_imports.py -q -o filterwarnings=ignore::ImportWarning 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
