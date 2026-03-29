#!/bin/bash
cd /src/kafka
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest -q tests/schema_registry/test_schema_id.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest