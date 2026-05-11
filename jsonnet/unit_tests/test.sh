#!/bin/bash
set -uo pipefail
cd /src/jsonnet
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS=''
export CXXFLAGS=''
export LDFLAGS=''
export RUSTFLAGS=''
rm -rf /tmp/jsonnet-cmake-build

cmake -S /src/jsonnet -B /tmp/jsonnet-cmake-build -DBUILD_TESTS=ON -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=ON -DBUILD_JSONNET=ON -DBUILD_JSONNETFMT=ON -DUSE_SYSTEM_GTEST=OFF -DBUILD_MAN_PAGES=OFF >/tmp/jsonnet-cmake-configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/jsonnet-cmake-configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cmake --build /tmp/jsonnet-cmake-build -j$(nproc) >/tmp/jsonnet-cmake-build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/jsonnet-cmake-build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cd /tmp/jsonnet-cmake-build || { echo "cd /tmp/jsonnet-cmake-build failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest