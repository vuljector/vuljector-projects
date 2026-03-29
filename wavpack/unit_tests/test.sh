#!/bin/bash
set -euo pipefail

cd /src/wavpack

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

./configure
make -j$(nproc)

./cli/wvtest --threads --exhaustive --short --no-extras 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic