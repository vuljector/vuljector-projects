#!/bin/bash
cd /src/cgif
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
meson setup /tmp/build --buildtype=debug && meson test -C /tmp/build --print-errorlogs 2>&1 | python3 /src/unit_tests/parse_results.py --framework meson
