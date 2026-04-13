#!/bin/bash
set -euo pipefail
cd /src/fluent-bit
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Install Python test deps required by the lightweight tests
pip3 install -q --disable-pip-version-check GitPython pytest || true

# Run the repo's small python tests under .github/scripts/tests and pipe through parser
pytest .github/scripts/tests -v --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest