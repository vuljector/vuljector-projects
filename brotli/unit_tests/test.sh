#!/bin/bash
set -uo pipefail
cd /src/brotli
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""

cmake -S /src/brotli -B /tmp/build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON >/tmp/cmake_configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/cmake_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cmake --build /tmp/build -j$(nproc) >/tmp/cmake_build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/cmake_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cd /tmp/build
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
