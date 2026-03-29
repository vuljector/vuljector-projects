#!/bin/bash
set -euo pipefail
cd /src/openh264
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
CFLAGS= make -B ENABLE64BIT=Yes BUILDTYPE=Release all plugin test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gtest