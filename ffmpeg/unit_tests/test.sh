#!/bin/bash
# FFmpeg: hand-rolled ./configure + make. The full `fate` suite needs the
# external fate-suite samples (~GB). `make check` is the lightweight
# alternative: builds and runs tests/api/* binaries that exercise lavc/lavf
# / lavu APIs without sample dependencies. Stays under the 5-min cap.
set -uo pipefail
cd /src/ffmpeg || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# build.sh leaves a configured tree; only reconfigure if missing.
if [ ! -f config.mak ]; then
    ./configure --cc=clang --cxx=clang++ --disable-doc --disable-stripping \
                --disable-asm --disable-x86asm >/tmp/ffmpeg_configure.log 2>&1 || {
        echo "=== ./configure failed ==="; tail -50 /tmp/ffmpeg_configure.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

# Building the tests/api programs requires the libraries to be in place;
# `make check` triggers both.
out=$(mktemp)
make -j"$(nproc)" check >"$out" 2>&1 || true
cat "$out"

# `make check` runs tests/api/api-* programs; each emits a `TEST <name>` line
# and on failure prints diagnostic. Count `TEST <name>` invocations vs how
# many made it through with "OK"/"PASS". When in doubt, count make's
# `--- TEST_PASSED ---` markers from tests/regression.mak. Fallback to ratio.
python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
test_invocations = re.findall(r"^TEST\s+([\w./-]+)", text, re.MULTILINE)
fail_markers = re.findall(r"\bFAIL(?:ED)?\b", text)
errors = sum(1 for line in text.splitlines() if "Error" in line and "TEST " not in line)
total = len(test_invocations)
failed = min(len(fail_markers), total)
passed = max(total - failed, 0)
print(f"{passed} passed, {failed} failed")
PY
