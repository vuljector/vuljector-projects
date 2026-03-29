#!/bin/bash
cd /src/phosphor-host-ipmid
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
meson test -C build --no-rebuild --print-errorlogs 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework meson