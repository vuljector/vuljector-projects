#!/bin/bash
# Test harness for OSS-Fuzz environment for the Arrow project
cd /src/arrow || exit 1
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Install minimal Python deps needed for the selected tests
pip3 install -q jinja2 click python-dotenv GitPython requests pytest || true
# Run a small pure-Python test file that doesn't require compiled pyarrow
pytest -q dev/test_merge_arrow_pr.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest