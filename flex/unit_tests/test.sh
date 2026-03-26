#!/bin/bash
cd /src/flex
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
if [ ! -f configure ]; then autoreconf -fi 2>&1 | tail -1; fi && ./configure 2>&1 | tail -1 && make -j$(nproc) 2>&1 | tail -1
make check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
