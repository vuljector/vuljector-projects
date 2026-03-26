#!/bin/bash
set -euo pipefail
cd /src/requests
# Clear sanitizer flags which break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Install test dependencies (be resilient if already installed)
pip3 install -e ".[test]" pytest -q || (pip3 install -e ".[test]" && pip3 install pytest -q)
# Run pytest over the tests directory and pipe to the provided parser
python3 -m pytest -q tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest