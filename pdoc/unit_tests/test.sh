#!/bin/bash
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cd /src/pdoc
python3 -m unittest pdoc.test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest