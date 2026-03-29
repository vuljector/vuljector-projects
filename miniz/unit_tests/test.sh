#!/bin/bash
cd /src/miniz
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
mkdir -p /tmp/build && cd /tmp/build && cmake /src/miniz -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON && cmake --build . -j$(nproc) && ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
