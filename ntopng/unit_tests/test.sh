#!/bin/bash
set -e
cd /src/ntopng
# Clear sanitizer flags (avoid breaking native builds)
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Ensure python package is importable
export PYTHONPATH=/src/ntopng/python:${PYTHONPATH}
# Provide a lightweight dummy pandas to satisfy imports in historical.py
cat > /src/ntopng/python/pandas.py <<'PY'
# Minimal stub for pandas used by unit tests import only
class DataFrame:
    pass

def read_csv(*a, **k):
    return DataFrame()

PY
# Install lightweight deps
pip3 install --no-cache-dir requests -q || true

python3 /workspace/run/unit_tests/test_ntopng_api.py 2>&1 \
  | python3 /workspace/run/unit_tests/parse_results.py --framework unittest
