#!/bin/bash
cd /src/openssl
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
./config 2>&1 | tail -1
make -j$(nproc) 2>&1 | tail -1
make test HARNESS_JOBS=$(nproc) 2>&1 | python3 /src/unit_tests/parse_results.py --framework tap
