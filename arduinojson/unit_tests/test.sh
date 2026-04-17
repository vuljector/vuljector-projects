#!/bin/bash
set -e
cd /src/arduinojson
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="-Wno-error=deprecated-literal-operator" LDFLAGS="" RUSTFLAGS=""
rm -rf /tmp/arduinojson-build
cmake -S /src/arduinojson -B /tmp/arduinojson-build -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DCMAKE_CXX_FLAGS='-Wno-error=deprecated-literal-operator' -DCMAKE_C_FLAGS='' >/dev/null
cmake --build /tmp/arduinojson-build -j$(nproc) >/dev/null
ctest --test-dir /tmp/arduinojson-build --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest