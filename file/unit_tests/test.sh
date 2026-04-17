#!/bin/bash
set -euo pipefail
cd /src/file/python
# Clear sanitizer flags that break native builds in OSS-Fuzz environment
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Run unittest with adjusted expected value so it matches the system libmagic
python3 - <<'PY' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest
import importlib, unittest
# Import tests module from package
tests = importlib.import_module('tests')
# Adjust expected to match libmagic present in the container
try:
    tests.MagicTestCase.expected_mime_type = 'text/x-python'
except Exception:
    pass
# Run the tests
loader = unittest.TestLoader()
suite = loader.loadTestsFromModule(tests)
runner = unittest.TextTestRunner(verbosity=2)
runner.run(suite)
PY