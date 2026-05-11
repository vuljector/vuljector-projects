#!/bin/bash
set -uo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
build_dir=/tmp/relic-build
cd /src/relic
if [ -d "$build_dir" ]; then
  cd "$build_dir" || { echo "cd $build_dir failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }
  cmake --build . -j$(nproc) >/tmp/relic_cmake_build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/relic_cmake_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
  }
else
  rm -rf "$build_dir"
  mkdir -p "$build_dir"
  cd "$build_dir" || { echo "cd $build_dir failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }
  cmake /src/relic -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON >/tmp/relic_cmake_configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/relic_cmake_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
  }
  cmake --build . -j$(nproc) >/tmp/relic_cmake_build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/relic_cmake_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
  }
fi
ctest --output-on-failure -j$(nproc) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest