#!/bin/bash
set -euo pipefail
cd /src/croaring
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
BUILD_DIR=/tmp/croaring-build
if [ ! -f "$BUILD_DIR/CTestTestfile.cmake" ]; then
  rm -rf "$BUILD_DIR"
  cmake -S /src/croaring -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DENABLE_ROARING_TESTS=ON >/tmp/croaring-cmake.log
  cmake --build "$BUILD_DIR" -j$(nproc) >/tmp/croaring-build.log
fi
ctest --test-dir "$BUILD_DIR" --output-on-failure -j1 -R '^(toplevel_unit|util_unit|cbitset_unit|array_container_unit)$' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest