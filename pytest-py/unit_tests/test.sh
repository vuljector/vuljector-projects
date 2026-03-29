#!/bin/bash
cd /src/py
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest testing -v --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest