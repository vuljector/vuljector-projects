#!/bin/bash
set -euo pipefail
cd /src/sqlalchemy
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest test/orm/test_query.py -q --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest