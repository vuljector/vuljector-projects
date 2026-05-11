#!/bin/bash
set -uo pipefail

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

cd /src/libzip
if ! command -v nihtest >/dev/null 2>&1; then
  python3 -m pip install nihtest || true
fi

BUILD_DIR=/tmp/libzip_build
rm -rf "$BUILD_DIR"

cmake -S . -B "$BUILD_DIR" -DBUILD_TESTING=ON -DBUILD_REGRESS=ON >/tmp/libzip_cmake_configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/libzip_cmake_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cmake --build "$BUILD_DIR" -j"$(nproc)" >/tmp/libzip_cmake_build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/libzip_cmake_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cd "$BUILD_DIR" || { echo "cd $BUILD_DIR failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest