#!/bin/bash
set -euo pipefail
cd /src/dask
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pip install -q pytest pytest-cov pytest-timeout jinja2 numpy
python3 -m pytest dask/array/tests/test_wrap.py dask/widgets/tests/test_widgets.py -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest