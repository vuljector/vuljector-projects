#!/bin/bash
cd /src/behaviortreecpp
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
rm -rf /tmp/btcpp-build
cmake -S /src/behaviortreecpp -B /tmp/btcpp-build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DBTCPP_SHARED_LIBS=OFF >/tmp/cmake_config.log && cmake --build /tmp/btcpp-build -j$(nproc) >/tmp/cmake_build.log && ctest --test-dir /tmp/btcpp-build --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gtest