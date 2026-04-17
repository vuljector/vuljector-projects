#!/bin/bash
set -euo pipefail
cd /src/freetype2-testing/external/freetype2
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Meson, ninja, and requests (for FreeType test font download)
python3 -m pip install --user -q meson ninja requests >/dev/null 2>&1 || true
python3 tests/scripts/download-test-fonts.py
# Use a dedicated build dir
BUILD_DIR=/tmp/ft_build
rm -rf "$BUILD_DIR"
meson setup "$BUILD_DIR" . -Dbuildtype=debug -Dtests=enabled \
  || meson setup "$BUILD_DIR" . -Dtests=enabled
# Build
ninja -C "$BUILD_DIR" -j"$(nproc)"

PASS=0
FAIL=0

run_test() {
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $name"; PASS=$((PASS + 1))
    else
        echo "FAIL: $name"; FAIL=$((FAIL + 1))
    fi
}

# Run meson tests (zlib:example, libpng:pngtest, regression/freetype2:issue-1063)
meson_out=$(meson test -C "$BUILD_DIR" --print-errorlogs 2>&1)
echo "$meson_out"
meson_ok=$(echo "$meson_out" | grep -oP 'Ok:\s*\K\d+' || echo 0)
meson_fail=$(echo "$meson_out" | grep -oP '(?<!Expected )Fail:\s*\K\d+' || echo 0)
PASS=$((PASS + meson_ok))
FAIL=$((FAIL + meson_fail))

# Build and run tool tests against meson-built shared library
FT_LIB="$BUILD_DIR/libfreetype.so"
FT_INC="include"

gcc -I"$FT_INC" src/tools/test_trig.c "$FT_LIB" -lm -Wl,-rpath,"$BUILD_DIR" \
    -o /tmp/ft_test_trig 2>/dev/null
run_test "test_trig" bash -c "/tmp/ft_test_trig 2>/dev/null | grep -q 'trigonometry test ok'"

gcc -I"$FT_INC" src/tools/test_bbox.c "$FT_LIB" -lm -Wl,-rpath,"$BUILD_DIR" \
    -o /tmp/ft_test_bbox 2>/dev/null
run_test "test_bbox" /tmp/ft_test_bbox

{ echo "$PASS passed"; echo "$FAIL failed"; } | python3 /workspace/run/unit_tests/parse_results.py --framework generic
