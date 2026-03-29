#!/bin/bash
set -euo pipefail
cd /src/pycups
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
if ! python3 -c 'import pytest' >/dev/null 2>&1; then
    pip3 install pytest -q
fi
pytest -q test.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest