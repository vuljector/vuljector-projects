#!/bin/bash
cd /src/dbus-broker
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
meson test -C build 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework meson