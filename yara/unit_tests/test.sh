#!/bin/bash
set -euo pipefail
cd /src/yara
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make -j"$(nproc)" check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools