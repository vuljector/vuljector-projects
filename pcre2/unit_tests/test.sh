#!/bin/bash
# pcre2: autotools. OSS-Fuzz run_tests.sh is just `ulimit + make check`.
set -uo pipefail
cd /src/pcre2 || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

ulimit -s 65536 || true

# build.sh leaves a partially configured tree (it loops over link sizes and
# the last iteration is what stays). Reconfigure to a clean state if needed.
if [ ! -f Makefile ]; then
    ./autogen.sh >/tmp/pcre2_autogen.log 2>&1 || true
    ./configure --enable-pcre2-16 --enable-pcre2-32 --enable-jit >/tmp/pcre2_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -80 /tmp/pcre2_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

make -j"$(nproc)" >/tmp/pcre2_make.log 2>&1 || {
    echo "=== make failed ==="; tail -120 /tmp/pcre2_make.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

out=$(mktemp)
make check >"$out" 2>&1 || true
cat "$out"

# pcre2's RunTest emits "All N tests are correctly handled" on success and
# "Test N FAILED" on individual failures. Translate to N passed, M failed.
python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
# Autotools-style summary lines, if present.
ap = sum(int(m) for m in re.findall(r"# PASS:\s*(\d+)", text))
af = sum(int(m) for m in re.findall(r"# FAIL:\s*(\d+)", text))
if ap or af:
    print(f"{ap} passed, {af} failed"); raise SystemExit
# Fallback: pcre2 RunTest output.
ok_lines = sum(1 for _ in re.finditer(r"^OK\b", text, re.MULTILINE))
ok_lines += sum(1 for _ in re.finditer(r"\bcorrectly handled\b", text))
fail_lines = sum(1 for _ in re.finditer(r"\bFAIL(ED)?\b", text))
print(f"{ok_lines} passed, {fail_lines} failed")
PY
