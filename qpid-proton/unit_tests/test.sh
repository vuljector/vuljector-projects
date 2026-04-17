#!/bin/bash
set -euo pipefail

cd /src/qpid-proton

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

mkdir -p /tmp/build
cd /tmp/build

cmake /src/qpid-proton -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON
cmake --build . -j$(nproc)

ctest --output-on-failure -E python-integration-test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest