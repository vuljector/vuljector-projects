#!/bin/bash
set -e
cd /src/nghttp2
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
[ -f configure ] || autoreconf -fi
./configure --disable-failmalloc >/tmp/nghttp2_configure.log
make -j$(nproc) >/tmp/nghttp2_make.log
make check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools