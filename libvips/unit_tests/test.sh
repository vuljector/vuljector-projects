#!/bin/bash
set -uo pipefail
cd /src/libvips
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null 2>&1 || true
apt-get install -y -qq libjpeg-dev libpng-dev libtiff-dev >/dev/null || true
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
rm -rf /tmp/build

meson setup /tmp/build --buildtype=debug >/tmp/libvips_meson_setup.log 2>&1 || {
    echo "=== meson setup failed ==="
    tail -50 /tmp/libvips_meson_setup.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

ninja -C /tmp/build tools/vips tools/vipsthumbnail tools/vipsheader >/tmp/libvips_ninja_build.log 2>&1 || {
    echo "=== ninja build failed ==="
    tail -80 /tmp/libvips_ninja_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

meson test -C /tmp/build --print-errorlogs 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework meson
