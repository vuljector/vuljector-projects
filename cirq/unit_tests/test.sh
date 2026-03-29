#!/bin/bash
set -euo pipefail
cd /src/Cirq
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest cirq-core/cirq/testing/pytest_utils_test.py cirq-core/cirq/_version_test.py cirq-google/cirq_google/_version_test.py -v --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest