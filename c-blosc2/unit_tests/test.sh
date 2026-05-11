#!/bin/bash
set -uo pipefail

# Run from repo root for stable paths; build out-of-tree with explicit -S/-B.
cd /src/c-blosc2
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

BUILD_DIR=/tmp/c-blosc2-ut-build
rm -rf "$BUILD_DIR"

# c-blosc2 uses BUILD_TESTS (not CMake's BUILD_TESTING). OSS-Fuzz uses the same flags.
cmake -S /src/c-blosc2 -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBUILD_TESTS=ON \
  -DBUILD_FUZZERS=OFF \
  -DBUILD_BENCHMARKS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_STATIC=ON \
  -DBUILD_SHARED=OFF \
  -DCMAKE_C_FLAGS="" \
  -DCMAKE_CXX_FLAGS="" >/tmp/c-blosc2_cmake_configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/c-blosc2_cmake_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cmake --build "$BUILD_DIR" -j"$(nproc)" >/tmp/c-blosc2_cmake_build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/c-blosc2_cmake_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

log=$(mktemp)
trap 'rm -f "$log"' EXIT
( cd "$BUILD_DIR" && ctest --output-on-failure ) >"$log" 2>&1
rc=$?
cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework ctest <"$log"
exit "$rc"
