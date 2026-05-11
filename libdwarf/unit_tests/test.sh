#!/bin/bash
# libdwarf-code: cmake. build.sh creates `build/` via `cmake ../ -DDO_TESTING=ON`.
# OSS-Fuzz run_tests.sh excludes the flaky `selftied` test.
set -uo pipefail
cd /src/libdwarf || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if [ ! -d build ]; then
    cmake -S . -B build -DDO_TESTING=ON >/tmp/ldw_cfg.log 2>&1 || {
        echo "=== cmake configure failed ==="; tail -80 /tmp/ldw_cfg.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

cmake --build build -j"$(nproc)" >/tmp/ldw_build.log 2>&1 || {
    echo "=== cmake --build failed ==="; tail -120 /tmp/ldw_build.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

out=$(mktemp)
ctest --test-dir build -C Release -j"$(nproc)" -E selftied >"$out" 2>&1 || true
cat "$out"

cat "$out" | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
