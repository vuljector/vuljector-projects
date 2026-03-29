#!/bin/bash
set -euo pipefail
cd /src/rapidjson
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
build_dir=/tmp/rapidjson-build-harness
rm -rf "$build_dir"
mkdir -p "$build_dir"
cd "$build_dir"
cmake /src/rapidjson -DCMAKE_BUILD_TYPE=Debug -DRAPIDJSON_BUILD_DOC=OFF -DRAPIDJSON_BUILD_EXAMPLES=OFF -DRAPIDJSON_BUILD_TESTS=ON -DRAPIDJSON_BUILD_THIRDPARTY_GTEST=ON -DCMAKE_CXX_FLAGS='-Wno-error=deprecated-declarations -Wno-error=uninitialized-const-pointer'
cmake --build . -j"$(nproc)"
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest