#!/bin/bash
cd /src/brotli
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
mkdir -p /tmp/build && cd /tmp/build
cmake /src/brotli -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON 2>&1 | tail -1
cmake --build . -j$(nproc) 2>&1 | tail -1
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
