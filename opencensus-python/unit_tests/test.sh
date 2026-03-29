#!/bin/bash
set -euo pipefail
cd /src/opencensus-python
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m unittest tests.unit.common.test_utils tests.unit.common.test_resource tests.unit.trace.test_span_context tests.unit.stats.test_measure 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest