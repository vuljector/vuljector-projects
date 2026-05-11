#!/bin/bash
set -uo pipefail

cd /src/hdf5
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Reuse the pre-built test tree from setup/build.sh (/src/hdf5/build-test) if
# available, so we skip the expensive cmake+compile step (~10+ min) at run time.
PREBUILD_DIR=/src/hdf5/build-test
if [ -f "$PREBUILD_DIR/CTestTestfile.cmake" ]; then
  BUILD_DIR="$PREBUILD_DIR"
else
  BUILD_DIR=/tmp/hdf5-ut-build
  rm -rf "$BUILD_DIR"
  cmake -S /src/hdf5 -B "$BUILD_DIR" \
    -DCMAKE_BUILD_TYPE=Debug \
    -DBUILD_TESTING=ON \
    -DCMAKE_C_FLAGS="" \
    -DCMAKE_CXX_FLAGS="" >/tmp/hdf5_cmake_configure.log 2>&1 || {
      echo "=== cmake configure failed ==="
      tail -50 /tmp/hdf5_cmake_configure.log
      printf '{"passed": 0, "failed": -1}\n'
      exit 0
  }
  cmake --build "$BUILD_DIR" -j"$(nproc)" >/tmp/hdf5_cmake_build.log 2>&1 || {
      echo "=== cmake --build failed ==="
      tail -80 /tmp/hdf5_cmake_build.log
      printf '{"passed": 0, "failed": -1}\n'
      exit 0
  }
fi

log=$(mktemp)
trap 'rm -f "$log"' EXIT
( cd "$BUILD_DIR" && ctest -j16 --output-on-failure ) >"$log" 2>&1
rc=$?
cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework ctest <"$log"
exit "$rc"
