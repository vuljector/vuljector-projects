#!/bin/bash
set -euo pipefail
cd /src/adsl
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -r requirements.txt
python3 -m pytest tests -v 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
SCRIPT_EOF && chmod +x /tmp/test_harness.sh