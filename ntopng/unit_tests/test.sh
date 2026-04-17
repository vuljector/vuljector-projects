#!/bin/bash
set -e
cd /src/ntopng
# Clear sanitizer flags (avoid breaking native builds)
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Ensure python package is importable
export PYTHONPATH=/src/ntopng/python:${PYTHONPATH}
# Provide a lightweight dummy pandas to satisfy imports in historical.py
cat > /src/ntopng/python/pandas.py <<'PY'
# Minimal stub for pandas used by unit tests import only
class DataFrame:
    pass

def read_csv(*a, **k):
    return DataFrame()

PY
# Install lightweight deps
pip3 install --no-cache-dir requests -q || true

# Create a small unittest that verifies constructing Ntopng with an unreachable URL raises ValueError
cat > /tmp/ntopng_unittest.py <<'PY'
import unittest
from ntopng.ntopng import Ntopng

class TestNtopng(unittest.TestCase):
    def test_invalid_url_raises(self):
        # Use a port that is very unlikely to be open to force a connection error
        with self.assertRaises(ValueError):
            Ntopng('admin','admin', None, 'http://127.0.0.1:59999')

if __name__ == '__main__':
    unittest.main()
PY

# Run the unittest and pipe through the parser (must be the last line)
python3 /tmp/ntopng_unittest.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest