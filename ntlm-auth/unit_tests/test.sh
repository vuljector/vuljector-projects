#!/bin/bash
cd /src/ntlm-auth
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -r requirements-test.txt
python3 -m pytest tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest