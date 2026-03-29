#!/bin/bash
cd /src/leptonica
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
./configure >/tmp/configure.log 2>&1 || (cat /tmp/configure.log && exit 1)
make -j$(nproc) check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools