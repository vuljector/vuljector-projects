#!/bin/bash
set -euo pipefail

# Full ctest run is ~400s+; keep a clean out-of-tree build (explicit -S/-B) so this
# does not clash with the OSS-Fuzz in-tree `build-dir` under /src/hdf5.
cd /src/hdf5
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

BUILD_DIR=/tmp/hdf5-ut-build
rm -rf "$BUILD_DIR"

cmake -S /src/hdf5 -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Debug \
  -DBUILD_TESTING=ON \
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
