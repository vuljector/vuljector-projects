#!/bin/bash
# libsass: ships two standalone C++ unit-test binaries under test/
# (test_shared_ptr and test_util_string). They're built by test/Makefile
# from a handful of libsass source files — no sass-spec/Ruby required.
set -uo pipefail
cd /src/libsass || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
unset CC CXX  # let test/Makefile pick a clean compiler

out=$(mktemp)
passed=0; failed=0

for tname in test_shared_ptr test_util_string; do
    if make -C test "build/$tname" >/tmp/libsass_${tname}_build.log 2>&1; then
        if (cd test && "./build/$tname") >>"$out" 2>&1; then
            echo "$tname: passed" >>"$out"
            passed=$((passed + 1))
        else
            echo "$tname: failed (exit $?)" >>"$out"
            failed=$((failed + 1))
        fi
    else
        echo "=== $tname build failed ==="; tail -30 /tmp/libsass_${tname}_build.log
        failed=$((failed + 1))
    fi
done

tail -40 "$out"

# Each test_* binary prints "Passed: N, failed: M." with internal subtest
# counts. Aggregate those for a finer-grained baseline than just
# "binaries-that-exited-zero".
python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
p = sum(int(m) for m in re.findall(r"Passed:\s*(\d+),\s*failed:\s*\d+", text))
f = sum(int(m) for m in re.findall(r"Passed:\s*\d+,\s*failed:\s*(\d+)", text))
print(f"{p} passed, {f} failed")
PY
