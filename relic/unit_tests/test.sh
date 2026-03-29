#!/bin/bash
set -euo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
build_dir=/tmp/relic-build
cd /src/relic
if [ -d "$build_dir" ]; then
  cd "$build_dir"
  cmake --build . -j$(nproc)
else
  rm -rf "$build_dir"
  mkdir -p "$build_dir"
  cd "$build_dir"
  cmake /src/relic -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
  cmake --build . -j$(nproc)
fi
ctest --output-on-failure -j$(nproc) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest