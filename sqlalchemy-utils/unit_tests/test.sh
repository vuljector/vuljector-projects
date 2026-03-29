#!/bin/bash
set -euo pipefail
cd /src/sqlalchemy-utils
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python -m pytest tests/test_proxy_dict.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest