#!/bin/bash
set -uo pipefail
cd /src/radare2

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Build radare2 if not already built
if [ ! -d r2-static ]; then
  echo "Building radare2..." >&2
  export USERCC=$CC
  export HOST_CC=$CC
  export NOLTO=1
  sed 's/gcc-ar/llvm-ar/g' -i sys/static.sh
  sys/static.sh >/tmp/radare2-static-build.log 2>&1 || {
    echo "=== sys/static.sh failed ==="
    tail -80 /tmp/radare2-static-build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
  }
fi

export LD_LIBRARY_PATH=/src/radare2/r2-static/usr/lib
export PATH=/src/radare2/r2-static/usr/bin:$PATH

make -C test/unit \
  LIBDIR=/src/radare2/r2-static/usr/lib \
  INCLUDEDIR=/src/radare2/libr/include \
  all >/tmp/radare2-unit-build.log 2>&1 || {
    echo "=== make -C test/unit all failed ==="
    tail -80 /tmp/radare2-unit-build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

excluded_re='^(test_bin|test_dwarf|test_dwarf_info|test_dwarf_integration|test_get_glibc_version|test_get_main_arena_offset|test_pdb)$'
tmp_output="$(mktemp)"

cd test
for bin in unit/bin/*; do
  name="$(basename "$bin")"
  if [[ "$name" =~ $excluded_re ]]; then
    continue
  fi
  "$bin" 2>&1 || true
done
cd /src/radare2

make -C test/unit \
  LIBDIR=/src/radare2/r2-static/usr/lib \
  INCLUDEDIR=/src/radare2/libr/include \
  BINS="$(cd test/unit && printf 'bin/%s ' $(ls bin | grep -Ev "$excluded_re"))" \
  run >"$tmp_output" 2>&1 || true

cat "$tmp_output"

python3 - "$tmp_output" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework custom
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(errors="ignore")
text = re.sub(r"\x1b\[[0-9;]*[A-Za-z]", "", text)
passed = len(re.findall(r" OK$", text, flags=re.MULTILINE))
failed = len(re.findall(r" ERR$", text, flags=re.MULTILINE))
print(f"{passed} passed, {failed} failed")
PY
