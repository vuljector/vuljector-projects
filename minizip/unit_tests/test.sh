#!/bin/bash
cd /src/minizip-ng
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cmake --build . --target gtest_minizip
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest