#!/bin/bash
set -uo pipefail
cd /src/protobuf-c
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make distclean >/dev/null 2>&1 || true

autoreconf -fi >/tmp/protobuf-c_autoreconf.log 2>&1 || {
    echo "=== autoreconf -fi failed ==="
    tail -50 /tmp/protobuf-c_autoreconf.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

./configure >/tmp/protobuf-c_configure.log 2>&1 || {
    echo "=== ./configure failed ==="
    tail -50 /tmp/protobuf-c_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

make -j4 >/tmp/protobuf-c_make.log 2>&1 || {
    echo "=== make -j4 (library build) failed ==="
    tail -80 /tmp/protobuf-c_make.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

make check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
