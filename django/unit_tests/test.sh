#!/bin/bash
set -euo pipefail
cd /src/django
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
export PYTHONPATH="/src/django:${PYTHONPATH:-}"
python3 -m unittest tests.utils_tests.test_dateparse 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest