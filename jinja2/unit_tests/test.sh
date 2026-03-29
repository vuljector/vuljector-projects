#!/bin/bash
set -euo pipefail
cd /src/jinja
python3 -m pip install -q pytest trio >/dev/null 2>&1 || true
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest