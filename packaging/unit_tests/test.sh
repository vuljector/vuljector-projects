#!/bin/bash
set -euo pipefail
cd /src/packaging
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install --no-input -e . pytest pretend tomli_w
python3 -m pytest tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest