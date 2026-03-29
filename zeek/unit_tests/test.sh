#!/bin/bash
set -euo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -e /src/zeek/auxil/zeek-client >/tmp/test_harness_install.log 2>&1 || true
pip3 install pytest >/tmp/test_harness_pytest_install.log 2>&1 || true
cd /src/zeek/auxil/zeek-client
python3 -m pytest tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest