#!/bin/bash
set -e
cd /src/dulwich
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 - <<'PY'
import importlib.util, subprocess, sys
if importlib.util.find_spec('pytest') is None:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pytest', '-q'])
PY
python3 -m pytest tests -q --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest