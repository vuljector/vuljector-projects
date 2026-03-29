#!/bin/bash
set -euo pipefail
cd /src/markdown-it-py
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -e .[testing]
pip3 install pytest-benchmark linkify-it-py
python3 -m pytest -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest