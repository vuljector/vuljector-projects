#!/bin/bash
cd /src/netcdf-c/build
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
ctest -E nczarr --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest