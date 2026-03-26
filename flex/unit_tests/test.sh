#!/bin/bash
# build.sh modifies /src/flex (applies patch, moves .o files), so clone a fresh copy
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
rm -rf /tmp/flex-test
git clone /src/flex /tmp/flex-test
cd /tmp/flex-test
autoreconf -fi 2>&1 | tail -1
./configure 2>&1 | tail -1
make -j$(nproc) 2>&1 | tail -1
make check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
