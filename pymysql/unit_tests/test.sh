#!/bin/bash
set -euo pipefail
cd /src/pymysql
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pip install -q pytest
python3 -m pytest -q \
  pymysql/tests/test_charset.py \
  pymysql/tests/test_optionfile.py \
  pymysql/tests/test_converters.py \
  pymysql/tests/test_err.py \
  2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
