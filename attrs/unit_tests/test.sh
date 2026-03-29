#!/bin/bash
cd /src/attrs
pip3 install -q pytest hypothesis >/dev/null 2>&1 || true
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest