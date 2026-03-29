#!/bin/bash
set -euo pipefail
cd /src/nbclassic
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install pytest-jupyter -q >/dev/null 2>&1 || true
python3 -m pytest nbclassic/bundler/tests/test_bundler_tools.py --tb=short -vv 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest