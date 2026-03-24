#!/bin/bash
cd /src/OpenJPH
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
mkdir -p /tmp/build && cd /tmp/build
cmake /src/OpenJPH -DCMAKE_BUILD_TYPE=Debug -DOJPH_BUILD_TESTS=ON 2>&1 | tail -1
cmake --build . -j$(nproc) 2>&1 | tail -1
ctest --output-on-failure 2>&1 | python3 /src/unit_tests/parse_results.py --framework ctest
