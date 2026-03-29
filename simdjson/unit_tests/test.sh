#!/bin/bash
set -euo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cd /src/simdjson
mkdir -p /tmp/build
cd /tmp/build
cmake /src/simdjson -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
cmake --build . -j$(nproc)
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest