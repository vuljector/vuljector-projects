#!/bin/bash
cd /src/oracle-py-cx
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pip install -q pytest || true
python3 -m pytest test/test_1000_module.py test/test_1500_types.py -v --maxfail=1 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
SCRIPT_EOF && chmod +x /tmp/test_harness.sh