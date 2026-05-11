#!/bin/bash
# unbound: autotools. OSS-Fuzz run_tests.sh just runs the `unittest` binary.
set -uo pipefail
cd /src/unbound || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if [ ! -f Makefile ]; then
    ./configure --with-libevent --with-libexpat=/usr >/tmp/unbound_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -50 /tmp/unbound_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

# `-k` lets us keep building unittest even if the daemon link step fails
# (missing libsystemd / ldns in the OSS-Fuzz minimal image). The unittest
# binary doesn't link against those.
make -k -j"$(nproc)" unittest >/tmp/unbound_make.log 2>&1 || true
if [ ! -x ./unittest ]; then
    echo "=== unittest binary missing ==="; tail -120 /tmp/unbound_make.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
fi

# unbound's unittest binary prints per-section "** test_X: passed" lines and
# at the end "Testing OK" on success.
out=$(mktemp)
./unittest >"$out" 2>&1 || true
cat "$out"

python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
# unbound's unitmain.c prints one "test <description>" line per test
# function and ends with "<N> checks ok." (total internal assertions). We
# count distinct test functions rather than assertions: assertions drift
# with refactors, but the set of test functions only changes if a unit
# test is added/removed. The "<N> checks ok." line still needs to be
# present at all (anything less = unittest exited early on a failed
# assertion); treat its absence as a hard fail.
ok_marker = re.search(r"^\s*\d+\s+checks ok\.", text, re.MULTILINE)
errors = re.search(r"\((\d+)\s+errors?\)", text)
test_lines = re.findall(r"^test ", text, re.MULTILINE)
total = len(test_lines)
if errors:
    f = int(errors.group(1))
    print(f"{max(total - f, 0)} passed, {f} failed")
elif ok_marker:
    print(f"{total} passed, 0 failed")
else:
    # unittest aborted before printing the OK summary — count nothing as passing.
    print(f"0 passed, {max(total, 1)} failed")
PY
