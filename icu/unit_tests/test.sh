#!/bin/bash
set -uo pipefail
cd /src/icu
# Clear sanitizer flags which break native builds in OSS-Fuzz environment
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Ensure pytest is available
python3 -m pip install -q pytest || true
# Run the test suites that need specific working directories and combine their output.
# The combined output is piped into the test results parser (pytest framework).
{
  (cd tools/commit-checker && pytest -q) || true
  (cd tools/py && pytest -q libs) || true
} 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest