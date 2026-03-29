#!/bin/bash
set -e
cd /src/scikit-learn
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -q -e .
python3 -m pytest sklearn/feature_selection/tests/test_variance_threshold.py sklearn/feature_selection/tests/test_chi2.py -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest