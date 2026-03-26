#!/bin/bash
cd /src/exiv2
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
apt-get update -qq 2>/dev/null && apt-get install -y -qq libfmt-dev libexpat1-dev >/dev/null 2>&1

if [ ! -f /usr/local/lib/libgtest.a ]; then
  apt-get update -qq 2>/dev/null && apt-get install -y -qq git >/dev/null 2>&1
  git clone --depth=1 -q https://github.com/google/googletest.git /tmp/googletest 2>/dev/null
  cmake /tmp/googletest -B /tmp/gtest-build -DCMAKE_CXX_FLAGS="-w" >/dev/null 2>&1
  cmake --build /tmp/gtest-build -j$(nproc) >/dev/null 2>&1
  cp /tmp/gtest-build/lib/*.a /usr/local/lib/ 2>/dev/null
  cp -r /tmp/googletest/googletest/include/gtest /usr/local/include/ 2>/dev/null
  cp -r /tmp/googletest/googlemock/include/gmock /usr/local/include/ 2>/dev/null
fi
mkdir -p /tmp/build && cd /tmp/build
cmake /src/exiv2 -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DEXIV2_ENABLE_UNIT_TESTS=ON 2>&1 | tail -1
cmake --build . -j$(nproc) 2>&1 | tail -1
ctest --output-on-failure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
