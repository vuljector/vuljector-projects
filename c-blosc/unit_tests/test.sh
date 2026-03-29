#!/bin/bash
set -euo pipefail
cd /src/c-blosc
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
BUILD_DIR=/tmp/c-blosc-build
rm -rf "$BUILD_DIR"
cmake -S /src/c-blosc -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
cmake --build "$BUILD_DIR" -j"$(nproc)"
cd "$BUILD_DIR"
ctest --output-on-failure --parallel "$(nproc)" 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest