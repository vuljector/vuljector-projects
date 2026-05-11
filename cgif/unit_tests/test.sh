#!/bin/bash
set -uo pipefail
cd /src/cgif
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

meson setup /tmp/build --buildtype=debug >/tmp/cgif_meson_setup.log 2>&1 || {
    echo "=== meson setup failed ==="
    tail -50 /tmp/cgif_meson_setup.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

meson test -C /tmp/build --print-errorlogs 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework meson
