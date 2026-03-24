#!/bin/bash
cd /src/unbound
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
if [ ! -f configure ]; then autoreconf -fi 2>&1 | tail -1; fi
./configure 2>&1 | tail -1
make -j$(nproc) 2>&1 | tail -1
OUTPUT=$(make check 2>&1)
echo "$OUTPUT"
PASSED=$(echo "$OUTPUT" | grep -c ' OK$')
FAILED=$(echo "$OUTPUT" | grep -c 'FAIL\|ERROR' || true)
echo "{\"passed\": $PASSED, \"failed\": $FAILED}"
