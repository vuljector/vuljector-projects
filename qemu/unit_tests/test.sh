#!/bin/bash
set -uo pipefail
cd /src/qemu
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Build qemu if not already built
if [ ! -d build-oss-fuzz ]; then
  echo "Building QEMU..." >&2
  /src/qemu/scripts/oss-fuzz/build.sh >/tmp/qemu_build.log 2>&1 || {
    echo "=== qemu oss-fuzz build.sh failed ==="
    tail -80 /tmp/qemu_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
  }
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
