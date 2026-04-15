#!/bin/bash
set -e
cd /src/grok
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
export PYTHONPATH="/workspace/run/unit_tests:${PYTHONPATH:-}"
python3 /workspace/run/unit_tests/run_tests.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic
