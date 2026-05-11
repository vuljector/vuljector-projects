#!/bin/bash
set -uo pipefail
cd /src/skia
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Ensure Python deps
if [ -f requirements.txt ]; then
  python3 -m pip install --upgrade pip setuptools >/dev/null 2>&1 || true
  python3 -m pip install -r requirements.txt --no-cache-dir || true
fi
export PYTHONPATH="/src/skia:${PYTHONPATH-}"
# Run unittest discovery across the repo for *_test.py files
exec python3 -m unittest discover -v -s . -p "*_test.py" 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest