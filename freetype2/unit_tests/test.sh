#!/bin/bash
set -euo pipefail
cd /src/freetype2-testing/external/freetype2
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Ensure meson and ninja are available
python3 -m pip install --user meson ninja >/dev/null 2>&1 || true
# Use a dedicated build dir
BUILD_DIR=/tmp/ft_build
rm -rf "$BUILD_DIR"
meson setup "$BUILD_DIR" . -Dbuildtype=debug || meson setup "$BUILD_DIR" .
# Build
ninja -C "$BUILD_DIR" -j$(nproc)
# Run tests via meson test
meson test -C "$BUILD_DIR" --print-errorlogs 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework meson