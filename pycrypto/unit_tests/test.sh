#!/bin/bash
set -euo pipefail
cd /src/pycrypto
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 setup.py test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest