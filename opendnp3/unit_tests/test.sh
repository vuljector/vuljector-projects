#!/bin/bash
set -euo pipefail
cd /src/opendnp3
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
rm -rf /tmp/build
cmake -S . -B /tmp/build -DDNP3_TESTS=ON -DCMAKE_BUILD_TYPE=Debug
cmake --build /tmp/build -j$(nproc)
cd /tmp/build
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest