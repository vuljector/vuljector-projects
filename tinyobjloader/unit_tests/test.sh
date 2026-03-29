#!/bin/bash
cd /src/tinyobjloader
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pip install -e .
python3 -m pytest tests/python/tinyobjloader_tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest