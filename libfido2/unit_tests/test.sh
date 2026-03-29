#!/bin/bash
cd /src/libfido2
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cmake --build build -j$(nproc)
cd build
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest