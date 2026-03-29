#!/bin/bash
cd /src/frr
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -q pytest || true
cd tests
python3 runtests.py . 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest