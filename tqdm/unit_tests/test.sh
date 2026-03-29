#!/bin/bash
set -e
cd /src/tqdm
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -q pytest pytest-asyncio pytest-timeout nbval >/dev/null 2>&1 || true
PYTHONWARNINGS=ignore python3 -m pytest tests/tests_version.py tests/tests_utils.py -q --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest