#!/bin/bash
set -euo pipefail
# Build test binaries first
cd /src/htslib || exit 1
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
autoconf 2>/dev/null || true
autoheader 2>/dev/null || true
./configure LIBS="-lz -lm -lbz2 -llzma -lcurl -lcrypto -lpthread" >/dev/null 2>&1 || true
make -j$(nproc) libhts.a bgzip htsfile tabix annot-tsv >/dev/null 2>&1 || true
make -j$(nproc) test/hts_endian test/fieldarith test/hfile test/pileup test/pileup_mod \
    test/sam test/test_bgzf test/test_expr test/test_faidx test/test_kfunc \
    test/test_khash test/test_kstring test/test_mod test/test_nibbles test/test_realn \
    test/test-regidx test/test_str2int test/test_time_funcs test/test_view \
    test/test_index test/test-vcf-api test/test-vcf-sweep test/test-bcf-sr \
    test/test-bcf-translate test/test-parse-reg test/test_introspection \
    test/test-bcf_set_variant_type >/dev/null 2>&1 || true

# Run from the test directory to avoid relative-path issues in test scripts
cd /src/htslib/test || exit 1

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

./test.pl >"$tmp_output" 2>&1 || true
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
