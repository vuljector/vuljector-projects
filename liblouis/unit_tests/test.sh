#!/bin/bash
set -uo pipefail
cd /src/liblouis
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if [ ! -f configure ]; then
    autoreconf -fi >/tmp/liblouis_autoreconf.log 2>&1 || {
        echo "=== autoreconf -fi failed ==="
        tail -50 /tmp/liblouis_autoreconf.log
        printf '{"passed": 0, "failed": -1}\n'
        exit 0
    }
fi

./configure >/tmp/liblouis_configure.log 2>&1 || {
    echo "=== ./configure failed ==="
    tail -50 /tmp/liblouis_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

make -j$(nproc) >/tmp/liblouis_make.log 2>&1 || {
    echo "=== make -j (library build) failed ==="
    tail -80 /tmp/liblouis_make.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

make check 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
