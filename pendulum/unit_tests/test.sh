#!/bin/bash
cd /src/pendulum
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS="" PYTHONPATH=/src/pendulum/src
python3 -m pytest tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest