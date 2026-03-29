#!/bin/bash
cd /src/util-linux
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
./tests/run.sh --srcdir=/src/util-linux --builddir=/src/util-linux --parallel --parsable --show-diff bitops sha1 md5 uuid 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools