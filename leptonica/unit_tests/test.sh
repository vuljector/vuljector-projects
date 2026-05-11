#!/bin/bash
set -uo pipefail
cd /src/leptonica
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" RUSTFLAGS=""

# Use pre-built test tree from setup/build.sh if available,
# otherwise configure and build now.
if [ ! -f Makefile ] || [ ! -x prog/scale_reg ]; then
    apt-get install -y -q libpng-dev libjpeg-dev libtiff-dev libwebp-dev zlib1g-dev >/dev/null 2>&1 || true

    ./configure \
        --with-libpng --with-zlib --with-jpeg --with-libwebp --with-libtiff \
        CC=gcc >/tmp/leptonica_configure.log 2>&1 || {
        echo "=== ./configure failed ==="
        tail -50 /tmp/leptonica_configure.log
        printf '{"passed": 0, "failed": -1}\n'
        exit 0
    }

    make -j"$(nproc)" >/tmp/leptonica_make.log 2>&1 || {
        echo "=== make -j (library build) failed ==="
        tail -80 /tmp/leptonica_make.log
        printf '{"passed": 0, "failed": -1}\n'
        exit 0
    }
fi

log=$(mktemp)
trap 'rm -f "$log"' EXIT
make check -j"$(nproc)" >"$log" 2>&1
cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework autotools <"$log"
