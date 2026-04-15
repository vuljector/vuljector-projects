#!/bin/bash
set -euo pipefail
cd /src/libvips
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null
apt-get install -y -qq libjpeg-dev libpng-dev libtiff-dev >/dev/null || true
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
rm -rf /tmp/build
meson setup /tmp/build --buildtype=debug >/dev/null
ninja -C /tmp/build tools/vips tools/vipsthumbnail tools/vipsheader >/dev/null
meson test -C /tmp/build --print-errorlogs 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework meson
