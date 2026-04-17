#!/bin/bash
set -euo pipefail
cd /src/libavc
# Clear sanitizer flags as required by OSS-Fuzz environment quirks
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Build native tests using CMake (do not use build.sh or fuzz targets)
BUILD_DIR=/tmp/build
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
cmake -DENABLE_TESTS=ON -DCMAKE_BUILD_TYPE=Debug /src/libavc
cmake --build . -j$(nproc)

# Create required resource directory and placeholder input files expected by tests
RES_DIR=/data/local/tmp/AvcEncTestRes
mkdir -p "$RES_DIR"
# Create the specific files referenced by the tests; zero-length is enough for fopen()
for f in bbb_352x288_420p_30fps_32frames.yuv football_qvga.yuv; do
  : > "$RES_DIR/$f"
done

# Run the gtest binary directly and pipe through the results parser (must be the last line)
# Use --gtest_color=no to avoid terminal color sequences
"$BUILD_DIR/AvcEncTest" --gtest_color=no 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gtest