#!/bin/bash
set -euo pipefail
cd /src/aspell/test
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
rm -rf build inst tmp warning-settings warning-settings.mk aspell6-en-2018.04.16-0 aspell6-en-2018.04.16-0.tar.bz2 test-res
(
  make -j"$(nproc)" all
  if [[ ! -f test-res ]]; then
    echo "test-res missing" >&2
    exit 1
  fi
  passed=$(grep -cve '^$' test-res)
  printf "%d passed\n0 failed\n" "$passed"
) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic