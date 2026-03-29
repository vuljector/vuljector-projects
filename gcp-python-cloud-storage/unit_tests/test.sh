#!/bin/bash
cd /src/python-storage
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest -q tests/unit tests/resumable_media/unit 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest