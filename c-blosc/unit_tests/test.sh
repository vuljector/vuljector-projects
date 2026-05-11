#!/bin/bash
set -uo pipefail
cd /src/c-blosc
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
BUILD_DIR=/tmp/c-blosc-build
rm -rf "$BUILD_DIR"

cmake -S /src/c-blosc -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON >/tmp/c-blosc_cmake_configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/c-blosc_cmake_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cmake --build "$BUILD_DIR" -j"$(nproc)" >/tmp/c-blosc_cmake_build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/c-blosc_cmake_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cd "$BUILD_DIR" || { echo "cd $BUILD_DIR failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }
ctest --output-on-failure --parallel "$(nproc)" 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest