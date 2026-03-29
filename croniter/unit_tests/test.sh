#!/bin/bash
set -euo pipefail
cd /src/croniter
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -e .
python3 -m pytest src/croniter/tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest