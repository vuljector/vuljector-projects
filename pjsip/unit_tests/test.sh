#!/bin/bash
set -euo pipefail
cd /src/pjsip
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
(
  cd tests/pjsua
  python3 run.py mod_run.py scripts-run/100_simple.py
  status=$?
  if [ "$status" -eq 0 ]; then
    echo "1 passed"
    echo "0 failed"
  else
    echo "0 passed"
    echo "1 failed"
  fi
  exit $status
) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic