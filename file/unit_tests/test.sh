#!/bin/bash
# file (libmagic): autotools. `make check` exercises the magic database.
set -uo pipefail
cd /src/file || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if [ ! -f Makefile ]; then
    autoreconf -fi >/tmp/file_autoreconf.log 2>&1 || true
    ./configure --enable-static >/tmp/file_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -50 /tmp/file_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

make -j"$(nproc)" >/tmp/file_make.log 2>&1 || {
    echo "=== make failed ==="; tail -120 /tmp/file_make.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

out=$(mktemp)
make check >"$out" 2>&1
rc=$?
cat "$out"

# `make check` walks tests/ running ./test -e <file>.testfile <file>.result
# for each. It prints "Running test: <name>" per case. There's no autotools
# "# PASS:" summary, so we count invocations vs explicit failure markers.
# If `make check` returned 0 (no diffs / no FAIL), every "Running test:" is
# a pass.
python3 - "$out" "$rc" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
rc = int(sys.argv[2])
total = len(re.findall(r"^Running test:\s*", text, re.MULTILINE))
explicit_fail = len(re.findall(r"\bFAIL(?:ED)?\b", text)) + len(re.findall(r"\bdiffer\b", text))
if rc == 0:
    print(f"{total} passed, 0 failed")
else:
    failed = max(explicit_fail, 1)
    print(f"{max(total - failed, 0)} passed, {failed} failed")
PY

