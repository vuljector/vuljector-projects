#!/bin/bash
set -e
cd /src/flask
# Clear sanitizer flags to avoid breaking native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Install test dependencies and pytest; tolerate failures but continue
python3 -m pip install -U pip setuptools wheel || true
python3 -m pip install -e .[tests] pytest -q || python3 -m pip install pytest -q || true
# Run pytest and pipe output to the provided parser
pytest -v --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest