#!/bin/bash
# haproxy: in-tree unit tests live under tests/unit/. The upstream
# `make unit-tests` driver only picks up `*.sh` files and most are gated
# behind features (USE_OPENSSL, USE_QUIC, …) the OSS-Fuzz build doesn't
# enable, so it only finds ist.sh. We additionally compile and run the
# arg-less stand-alone `tests/unit/test-*.c` programs that don't depend
# on the haproxy daemon's internal headers.
set -uo pipefail
cd /src/haproxy || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# --- 1. ist.sh via the upstream unit-tests driver ----------------------
out_drv=$(mktemp)
make unit-tests >"$out_drv" 2>&1 || true
cat "$out_drv"

drv_pass=$(grep -oE "[0-9]+ tests? passed" "$out_drv" | tail -1 | grep -oE "[0-9]+")
drv_fail=$(grep -oE "[0-9]+ tests? failed" "$out_drv" | tail -1 | grep -oE "[0-9]+")
drv_pass=${drv_pass:-0}
drv_fail=${drv_fail:-0}

# --- 2. stand-alone arg-less C tests -----------------------------------
extra_pass=0; extra_fail=0
out_extra=$(mktemp)

build_and_run() {
    local src=$1 args=$2 label=$3
    local bin=/tmp/hap_${label}
    if clang -I include -I include/import -O1 -o "$bin" "$src" -lpthread >/tmp/hap_${label}_build.log 2>&1; then
        if "$bin" $args >>"$out_extra" 2>&1; then
            echo "${label}: ok" >>"$out_extra"; extra_pass=$((extra_pass + 1))
        else
            echo "${label}: fail (exit $?)" >>"$out_extra"; extra_fail=$((extra_fail + 1))
        fi
    else
        echo "${label}: build failed" >>"$out_extra"
        tail -10 /tmp/hap_${label}_build.log >>"$out_extra"
        extra_fail=$((extra_fail + 1))
    fi
}
# test-int-range: args optional (defaults work)
build_and_run tests/unit/test-int-range.c "" int-range
# test-1-among: needs a mask + bit; use a benign pair
build_and_run tests/unit/test-1-among.c "255 0" one-among
# test-list: stress test, accepts thread count
build_and_run tests/unit/test-list.c "1" mt-list

tail -30 "$out_extra"

total_pass=$((drv_pass + extra_pass))
total_fail=$((drv_fail + extra_fail))
echo "${total_pass} passed, ${total_fail} failed" \
    | python3 /workspace/run/unit_tests/parse_results.py --framework generic
