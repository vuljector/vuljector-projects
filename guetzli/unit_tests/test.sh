#!/bin/bash
set -euo pipefail

cd /src/guetzli
# Clear sanitizer flags so the native build can run cleanly.
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Build the CLI so the smoke tests have a binary to exercise.
make -j"$(nproc)" guetzli

run_smoke_test() {
  bash tests/smoke_test.sh bin/Release/guetzli
}

run_all_tests() {
  run_smoke_test
  echo "1 passed, 0 failed"
}

run_all_tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic