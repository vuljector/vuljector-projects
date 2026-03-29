#!/bin/bash
set -euo pipefail
cd /src/google-api-python-client
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -q pytest google-auth google-auth-httplib2 mox parameterized pyopenssl cryptography==38.0.3 webtest coverage
python3 -m pytest tests -v --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest