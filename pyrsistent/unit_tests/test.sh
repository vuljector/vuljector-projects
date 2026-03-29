#!/bin/bash
set -euo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cd /src/pyrsistent
pip3 install --upgrade pip
pip3 install pytest hypothesis typing_extensions
python3 -m pytest tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest