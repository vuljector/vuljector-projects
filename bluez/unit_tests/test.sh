#!/bin/bash
# bluez: autotools. OSS-Fuzz run_tests.sh moves two flaky test files aside,
# then loops over unit/test-*.c building + running each. Mirror that.
set -uo pipefail
cd /src/bluez || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if [ ! -f Makefile ]; then
    ./bootstrap >/tmp/bluez_bootstrap.log 2>&1 || true
    ./configure --enable-static --disable-systemd --disable-udev \
                --disable-cups --disable-obex --disable-mesh \
                >/tmp/bluez_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -50 /tmp/bluez_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

make -j"$(nproc)" >/tmp/bluez_make.log 2>&1 || true   # ok if some fuzzer targets fail

# Move out tests that the OSS-Fuzz upstream excludes (flaky/needs hw).
mv unit/test-mesh-crypto.c /tmp/ 2>/dev/null || true
mv unit/test-midi.c        /tmp/ 2>/dev/null || true

out=$(mktemp)
passed=0; failed=0
for unit_test in unit/test-*.c; do
    [ -e "$unit_test" ] || continue
    name="${unit_test%.*}"          # unit/test-foo
    if make -j"$(nproc)" "$name" >/tmp/bluez_unit_build.log 2>&1; then
        if ./"$name" >>"$out" 2>&1; then
            passed=$((passed + 1))
        else
            failed=$((failed + 1))
        fi
    else
        failed=$((failed + 1))
    fi
done
# Restore moved files
mv /tmp/test-mesh-crypto.c unit/ 2>/dev/null || true
mv /tmp/test-midi.c        unit/ 2>/dev/null || true

# Cap the test output at a reasonable size (tap output can be huge).
tail -200 "$out"
echo "${passed} passed, ${failed} failed" \
    | python3 /workspace/run/unit_tests/parse_results.py --framework generic
