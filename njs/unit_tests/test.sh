#!/bin/bash
# njs (nginx JS engine): custom Makefile. OSS-Fuzz run_tests.sh is `make unit_test`.
set -uo pipefail
cd /src/njs || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# njs uses a hand-rolled `./configure` shell script (not autotools).
if [ ! -f build/Makefile ]; then
    ./configure >/tmp/njs_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -50 /tmp/njs_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

make -j"$(nproc)" >/tmp/njs_make.log 2>&1 || {
    echo "=== make failed ==="; tail -120 /tmp/njs_make.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

# `make unit_test` builds and runs the C-level unit tests under src/test/.
out=$(mktemp)
make unit_test >"$out" 2>&1 || true
cat "$out"

# njs unit-test harness emits one line per case "<name>: passed" / "<name>: failed"
# plus aggregate "tests passed: N" / "tests failed: N" if recent enough.
python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
# njs's unit-test runner ends with:
#   TOTAL: PASSED [N/N]   on success
#   TOTAL: FAILED [k/N]   on failure (k = passed, N = total)
m = re.search(r"TOTAL:\s*(PASSED|FAILED)\s*\[(\d+)/(\d+)\]", text)
if m:
    status, p, total = m.group(1), int(m.group(2)), int(m.group(3))
    f = total - p
    print(f"{p} passed, {f} failed")
else:
    # Fallback: per-category lines "<name> tests: PASSED [k/N]"
    pp = sum(int(x) for x in re.findall(r"PASSED\s*\[(\d+)/\d+\]", text))
    print(f"{pp} passed, 0 failed")
PY
