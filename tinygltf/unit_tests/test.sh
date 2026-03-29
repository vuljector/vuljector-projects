#!/bin/bash
set -euo pipefail
cd /src/tinygltf
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
rm -rf /tmp/tinygltf-test-build
cmake -S /src/tinygltf -B /tmp/tinygltf-test-build -DCMAKE_BUILD_TYPE=Debug -DTINYGLTF_BUILD_TESTS=ON >/tmp/tinygltf-cmake.log 2>&1
cmake --build /tmp/tinygltf-test-build -j$(nproc) >/tmp/tinygltf-build.log 2>&1
ctest --test-dir /tmp/tinygltf-test-build --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest