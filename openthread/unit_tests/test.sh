#!/bin/bash
set -euo pipefail
cd /src/openthread
# Clear sanitizer flags so native builds/tests aren't broken
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Ensure pytest is available
python3 -m pip install -q pytest || true

# Make sure test modules can be imported
export PYTHONPATH="/src/openthread/tests/scripts/thread-cert:${PYTHONPATH:-}"

# Run a small, self-contained test suite that is expected to pass in this environment
python3 -m pytest -q tests/scripts/thread-cert/test_common.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest