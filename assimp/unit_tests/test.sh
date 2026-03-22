#!/bin/bash
cd /src/assimp
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="-Wno-error" LDFLAGS=""
mkdir -p /tmp/build && cd /tmp/build
cmake /src/assimp -DCMAKE_BUILD_TYPE=Debug -DASSIMP_BUILD_TESTS=ON -DASSIMP_BUILD_ZLIB=ON -DASSIMP_WARNINGS_AS_ERRORS=OFF >/dev/null 2>&1
cmake --build . -j$(nproc) 2>&1 | tail -1
# gtest binary not registered with ctest — run directly and convert output
(
  cd /src/assimp
  OUTPUT=$(/tmp/build/bin/unit 2>&1)
  echo "$OUTPUT"
) 2>&1 | python3 /src/unit_tests/parse_results.py --framework gtest
