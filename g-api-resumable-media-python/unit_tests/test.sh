#!/bin/bash
set -euo pipefail
cd /src/google-resumable-media-python
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install pytest google-auth requests test_utils
python3 -m pytest tests tests_async -v --maxfail=1 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest