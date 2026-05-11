#!/bin/bash
# open5gs: meson-based. build.sh runs `meson setup builddir -Dfuzzing=true`
# and `ninja`. The test target is the meson test suite under tests/.
set -uo pipefail
cd /src/open5gs || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
# freeDiameter macros trip clang's -Werror=compound-token-split-by-macro;
# OSS-Fuzz build.sh suppresses both that and -Wformat. Mirror those here.
export CFLAGS="-Wno-compound-token-split-by-macro -Wno-format -Wno-error"
export CXXFLAGS="$CFLAGS"
export LDFLAGS="" RUSTFLAGS=""

# Use a separate build dir so we don't poison the fuzzer build at builddir/.
if [ ! -d build_native ]; then
    meson setup build_native --default-library=static >/tmp/o5gs_setup.log 2>&1 || {
        echo "=== meson setup failed ==="
        tail -80 /tmp/o5gs_setup.log
        printf '{"passed": 0, "failed": -1}\n'
        exit 0
    }
fi

ninja -C build_native >/tmp/o5gs_build.log 2>&1 || {
    echo "=== ninja build failed ==="
    tail -120 /tmp/o5gs_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

# Run a fast subset: unit tests under tests/unit + tests/common.
# Network-dependent tests (registration, csfb, …) need a running mongo and
# exceed the 5-min budget; skip them.
out=$(mktemp)
meson test -C build_native --print-errorlogs --suite unit --suite common >"$out" 2>&1 || true
cat "$out"

cat "$out" | python3 /workspace/run/unit_tests/parse_results.py --framework meson
