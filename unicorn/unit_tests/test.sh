#!/bin/bash
set -euo pipefail
cd /src/unicorn
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

passed=0
failed=0

for bin in \
  build/sample_x86 \
  build/sample_arm \
  build/sample_arm64 \
  build/sample_mips \
  build/sample_sparc \
  build/sample_m68k \
  build/sample_ppc \
  build/sample_riscv \
  build/sample_s390x \
  build/sample_tricore \
  build/sample_ctl \
  build/sample_x86_32_gdt_and_seg_regs
do
  [ -x "$bin" ] || continue
  if "$bin" >/dev/null 2>&1; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
done

printf '%d passed, %d failed\n' "$passed" "$failed" | python3 /workspace/run/unit_tests/parse_results.py --framework generic
