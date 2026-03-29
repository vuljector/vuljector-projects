#!/bin/bash
set -euo pipefail
cd /src/botocore
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install pytest -q >/dev/null 2>&1 || true
python3 -m pytest tests/unit/test_exceptions.py -q --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest