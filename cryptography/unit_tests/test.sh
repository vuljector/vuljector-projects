#!/bin/bash
set -euo pipefail
cd /src/cryptography
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -q -e '.[test]' pytest pytest-benchmark
python3 -m pytest tests/test_meta.py -q --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest