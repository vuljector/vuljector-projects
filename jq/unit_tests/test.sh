#!/bin/bash
# jq: autotools. OSS-Fuzz run_tests.sh chains the in-tree test programs.
set -uo pipefail
cd /src/jq || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if [ ! -f Makefile ]; then
    autoreconf -fi >/tmp/jq_autoreconf.log 2>&1 || true
    ./configure --with-oniguruma=builtin >/tmp/jq_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -50 /tmp/jq_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

make -j"$(nproc)" >/tmp/jq_make.log 2>&1 || {
    echo "=== make failed ==="; tail -120 /tmp/jq_make.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

# `make check` recurses into vendor/oniguruma whose own test suite fails
# in this sandbox — those failures aren't jq regressions. Run only jq's
# tests by limiting to the top-level Makefile (no recursion).
out=$(mktemp)
make check-am >"$out" 2>&1 || true
cat "$out"

cat "$out" | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
