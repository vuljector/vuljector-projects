#!/bin/bash
set -euo pipefail

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

cd /src/libzip
if ! command -v nihtest >/dev/null 2>&1; then
  python3 -m pip install nihtest
fi

BUILD_DIR=/tmp/libzip_build
rm -rf "$BUILD_DIR"
cmake -S . -B "$BUILD_DIR" -DBUILD_TESTING=ON -DBUILD_REGRESS=ON
cmake --build "$BUILD_DIR" -j"$(nproc)"
cd "$BUILD_DIR"
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest