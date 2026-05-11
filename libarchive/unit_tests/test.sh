#!/bin/bash
# libarchive: cmake. OSS-Fuzz build.sh creates `libarchive/build2/` and ctest
# runs from there. We mirror oss-fuzz/projects/libarchive/run_tests.sh,
# excluding tests known-flaky in that environment.
set -uo pipefail
cd /src/libarchive || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

export ASAN_OPTIONS="detect_leaks=0:allocator_may_return_null=1"

if [ ! -d libarchive/build2 ]; then
    cmake -S . -B libarchive/build2 -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON >/tmp/larch_cfg.log 2>&1 || {
        echo "=== cmake configure failed ==="; tail -80 /tmp/larch_cfg.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

cmake --build libarchive/build2 -j"$(nproc)" >/tmp/larch_build.log 2>&1 || {
    echo "=== cmake --build failed ==="; tail -120 /tmp/larch_build.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

out=$(mktemp)
ctest --test-dir libarchive/build2 -j"$(nproc)" -E \
    "libarchive_test_compat_zip_4|libarchive_test_read_format_cpio_bin.*|libarchive_test_read_pax_truncated|bsdcpio_test_basic|bsdcpio_test_option_0|bsdcpio_test_option_L_upper|bsdcpio_test_option_d|bsdcpio_test_option_f|bsdcpio_test_option_m|bsdcpio_test_option_t" \
    >"$out" 2>&1 || true
cat "$out"

cat "$out" | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
