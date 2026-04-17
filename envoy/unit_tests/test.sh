#!/bin/bash
cd /src/envoy
# Clear sanitizer flags for native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Ensure pytest is available
python3 -m pip install -q pytest || true
# Create a local conftest to provide the 'writer' fixture used by the tests
cat > test/common/json/config_schemas_test_data/conftest.py <<'PY'
import pytest
from util import TestWriter

@pytest.fixture
def writer(tmp_path):
    return TestWriter(str(tmp_path))
PY
# Run the tests in that directory with an isolated pytest config to avoid repo plugins
pytest -c /dev/null -q test/common/json/config_schemas_test_data 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest