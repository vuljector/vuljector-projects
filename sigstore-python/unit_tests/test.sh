#!/bin/bash
cd /src/sigstore-python
pip3 install -q -e ".[test]" 2>/dev/null || pip3 install -q -e . pytest pretend pytest-mock 2>/dev/null
python3 -m pytest test/unit \
  -v --tb=no -q --override-ini="addopts=" -p no:cacheprovider 2>&1 | \
  python3 /src/unit_tests/parse_results.py --framework pytest
