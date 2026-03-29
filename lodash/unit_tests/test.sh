#!/bin/bash
set -euo pipefail
cd /src/lodash
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
{
  node test/test
  node test/test-fp
} 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools