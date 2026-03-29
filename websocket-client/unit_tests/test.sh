#!/bin/bash
set -euo pipefail
cd /src/websocket-client
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -q pytest websockets >/dev/null 2>&1 || true
python3 -m pytest websocket/tests -q --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest