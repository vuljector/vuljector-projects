#!/bin/bash
set -euo pipefail
cd /src/model-transparency
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python -m pip install -q pytest PyKCS11 || true
python -m pytest tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest