#!/bin/bash
set -euo pipefail
cd /src/google-auth-library-python
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest tests tests_async -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest