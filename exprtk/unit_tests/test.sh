#!/bin/bash
set -euo pipefail
cd /src/exprtk
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
c++ -std=c++11 -O2 -DNDEBUG -Wall -Wextra -Werror -Wno-long-long -o /tmp/exprtk_test exprtk_test.cpp -lm
{
  /tmp/exprtk_test | awk '
    /Result: SUCCESS/ {p++}
    /Result: FAILURE/ {f++}
    END {print p+0 " passed, " f+0 " failed"}
  '
} 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic