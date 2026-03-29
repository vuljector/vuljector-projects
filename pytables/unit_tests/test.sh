#!/bin/bash
set -euxo pipefail
cd /src/pytables
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
export PYTHONPATH="/src/pytables/build/lib.linux-x86_64-cpython-311:/src/pytables"
python3 setup.py build_ext --inplace || true
python3 -m tables.tests.test_suite 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest