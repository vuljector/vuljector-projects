#!/bin/bash
cd /src/mbedtls
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
apt-get update -qq 2>/dev/null && apt-get install -y -qq git python3 >/dev/null 2>&1
# Init the framework submodule
if [ ! -f framework/CMakeLists.txt ]; then
  rm -rf framework
  git clone --depth=1 -q https://github.com/Mbed-TLS/mbedtls-framework.git framework 2>/dev/null
fi
mkdir -p /tmp/build && cd /tmp/build
cmake /src/mbedtls -DCMAKE_BUILD_TYPE=Debug -DENABLE_TESTING=ON -DMBEDTLS_FATAL_WARNINGS=OFF 2>&1 | tail -1
cmake --build . -j$(nproc) 2>&1 | tail -1
ctest --output-on-failure 2>&1 | python3 /src/unit_tests/parse_results.py --framework ctest
