#!/bin/bash
set -euo pipefail

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
    -DCMAKE_CXX_FLAGS=""
  cmake --build "$BUILD_DIR" -j"$(nproc)"
fi

log=$(mktemp)
trap 'rm -f "$log"' EXIT
set +e
( cd "$BUILD_DIR" && ctest --output-on-failure ) >"$log" 2>&1
rc=$?
set -e
cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework ctest <"$log"
exit "$rc"
