#!/bin/bash
cd /src/setuptools
pip3 install -q -e . pytest "jaraco.path" "jaraco.envs" "jaraco.test" "jaraco.functools" 2>/dev/null
python3 -m pytest setuptools/tests \
  --ignore=setuptools/tests/config/test_apply_pyprojecttoml.py \
  --ignore=setuptools/tests/compat \
  --ignore=setuptools/tests/test_dist.py \
  --ignore=setuptools/tests/test_find_packages.py \
  --ignore=setuptools/tests/test_find_py_modules.py \
  -v --tb=no -q --override-ini="addopts=" -p no:cacheprovider 2>&1 | \
  python3 /workspace/run/unit_tests/parse_results.py --framework pytest
