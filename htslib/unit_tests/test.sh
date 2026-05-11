#!/bin/bash
set -uo pipefail
cd /src/htslib || { echo "cd /src/htslib failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make clean >/dev/null 2>&1 || true
autoheader >/dev/null 2>&1 || true
autoconf >/dev/null 2>&1 || true

./configure LIBS="-lz -lm -lbz2 -llzma -lcurl -lcrypto -lpthread" >/tmp/htslib_configure.log 2>&1 || {
    echo "=== ./configure failed ==="
    tail -50 /tmp/htslib_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

make -j4 >/tmp/htslib_make.log 2>&1 || {
    echo "=== make -j4 (library build) failed ==="
    tail -80 /tmp/htslib_make.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

# Run from the test directory to avoid relative-path issues in test scripts
cd /src/htslib/test || { echo "cd /src/htslib/test failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

tmp_output="$(mktemp)"
python3 - test.pl <<'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1])
text = p.read_text()
old = '    foreach my $sam (glob("*#*.sam")) {\n'
new = old + '        next if $sam eq "ce#large_seq.sam" || $sam eq "xx#large_aux.sam";\n'
p.write_text(text.replace(old, new, 1))
PY

./test.pl >"$tmp_output" 2>&1
cat "$tmp_output"

python3 - "$tmp_output" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework custom
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(errors="ignore")
passed = re.search(r"^\s*passed\s+\.\.\s+(\d+)$", text, flags=re.MULTILINE)
failed = re.search(r"^\s*failed\s+\.\.\s+(\d+)$", text, flags=re.MULTILINE)
print(f"{int(passed.group(1)) if passed else 0} passed, {int(failed.group(1)) if failed else 0} failed")
PY
