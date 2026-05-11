#!/bin/bash
set -uo pipefail

cd /src/simdjson
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# OSS-Fuzz run_tests.sh — avoid LSAN noise in this image.
export ASAN_OPTIONS=detect_leaks=0

# Use the existing Ninja build at /src/simdjson/build (same as fuzz). A fresh
# CMake tree under /tmp misses generator steps and breaks <ranges> with the
# image toolchain; the fuzz tree also may not have every test binary until
# `all_tests` is built (e.g. amalgamate_demo).
ninja -C /src/simdjson/build -j"$(nproc)" all_tests >/tmp/simdjson_ninja_build.log 2>&1 || {
    echo "=== ninja all_tests failed ==="
    tail -80 /tmp/simdjson_ninja_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

log=$(mktemp)
trap 'rm -f "$log"' EXIT

# Same exclusions as oss-fuzz/projects/simdjson/run_tests.sh
EXCL='minify_tests|prettify_tests|ondemand_tostring_tests|ondemand_cacheline|builder_string_builder_tests'

ctest --test-dir /src/simdjson/build -j"$(nproc)" -E "$EXCL" >"$log" 2>&1
rc=$?

cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework ctest <"$log"
exit "$rc"
