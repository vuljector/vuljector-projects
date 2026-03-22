#!/bin/bash
cd /src/hdf5
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
mkdir -p /tmp/build && cd /tmp/build
cmake /src/hdf5 -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DHDF5_BUILD_TOOLS=OFF -DHDF5_BUILD_EXAMPLES=OFF 2>&1 | tail -1
cmake --build . -j$(nproc) 2>&1 | tail -1
ctest -V 2>&1 | python3 /src/unit_tests/parse_results.py --framework ctest
