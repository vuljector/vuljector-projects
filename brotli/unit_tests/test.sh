#!/bin/bash
cd /src/brotli
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
cmake -S /src/brotli -B /tmp/build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON 2>&1 | tail -1
cmake --build /tmp/build -j$(nproc) 2>&1 | tail -1
cd /tmp/build && ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
