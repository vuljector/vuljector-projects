#!/bin/bash
set -euo pipefail
cd /src/tcmalloc
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
mkdir -p /tmp/tcmalloc-build
cd /tmp/tcmalloc-build
cmake /src/tcmalloc -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON >/tmp/tcmalloc-cmake.log 2>&1
cmake --build . --target tcmalloc_testing_malloc_extension_system_malloc_test -j"$(nproc)" >/tmp/tcmalloc-build.log 2>&1
./tcmalloc/testing/tcmalloc_testing_malloc_extension_system_malloc_test --gtest_color=no 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gtest