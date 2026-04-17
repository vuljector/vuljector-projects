#!/bin/bash
set -euo pipefail
cd /src/leptonica
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" RUSTFLAGS=""

# Use pre-built test tree from setup/build.sh if available,
# otherwise configure and build now.
if [ ! -f Makefile ] || [ ! -x prog/scale_reg ]; then
    apt-get install -y -q libpng-dev libjpeg-dev libtiff-dev libwebp-dev zlib1g-dev >/dev/null 2>&1
    ./configure \
        --with-libpng --with-zlib --with-jpeg --with-libwebp --with-libtiff \
        CC=gcc >/dev/null 2>&1
    make -j"$(nproc)" >/dev/null 2>&1
fi

log=$(mktemp)
trap 'rm -f "$log"' EXIT
set +e
make check -j"$(nproc)" >"$log" 2>&1
set -e
cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework autotools <"$log"
