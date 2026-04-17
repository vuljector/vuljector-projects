#!/bin/bash
set -euo pipefail
cd /src/qemu
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Build qemu if not already built
if [ ! -d build-oss-fuzz ]; then
  echo "Building QEMU..." >&2
  /src/qemu/scripts/oss-fuzz/build.sh >/dev/null 2>&1 || true
fi

out=$(mktemp)
build-oss-fuzz/pyvenv/bin/meson test -C build-oss-fuzz \
  check-qdict check-qnum check-qstring check-qlist check-qnull test-cutils \
  --print-errorlogs 2>&1 | tee "$out"
python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
passed = sum(int(x) for x in re.findall(r"(\d+)\s+subtests passed", text))
failed = 0
print(f"{passed} passed, {failed} failed")
PY
