#!/bin/bash
set -euo pipefail

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
  -DCMAKE_CXX_FLAGS=""

cmake --build "$BUILD_DIR" -j"$(nproc)"

log=$(mktemp)
trap 'rm -f "$log"' EXIT
set +e
( cd "$BUILD_DIR" && ctest --output-on-failure ) >"$log" 2>&1
rc=$?
set -e
cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework ctest <"$log"
exit "$rc"
