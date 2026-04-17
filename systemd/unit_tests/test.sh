#!/bin/bash
cd /src/systemd
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install --no-cache-dir pytest pefile >/tmp/test_harness_pip.log 2>&1 || true
python3 -m pytest src/ukify/test/test_ukify.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
SCRIPT_EOF && chmod +x /tmp/test_harness.sh