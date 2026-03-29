#!/bin/bash
set -eu
cd /src/ply
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pip install . -q
( python3 tests/testlex.py && python3 tests/testyacc.py ) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest