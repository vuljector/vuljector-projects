#!/bin/bash
set -euo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cd /src/cbor2
source /root/.cargo/env >/dev/null 2>&1 || true
python3 -m pip install -U pip >/tmp/test_harness_pip.log 2>&1 || true
python3 -m pip install pytest hypothesis >/tmp/test_harness_pip.log 2>&1 || true
pytest tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest