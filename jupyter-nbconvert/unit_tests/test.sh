#!/bin/bash
set -euo pipefail
cd /src/nbconvert
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install --upgrade six
python3 -m pip install -e .[test]
export PYTHONWARNINGS=ignore::ImportWarning
python3 -m pytest tests -vv --maxfail=1 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest