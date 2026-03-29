#!/bin/bash
cd /src/astroid
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest tests -q -W ignore::ImportWarning -W ignore::PendingDeprecationWarning -W ignore::DeprecationWarning 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest