#!/bin/bash
cd /src/pem
pip3 install -q certifi pyOpenSSL pytest pem 2>/dev/null
pip3 install -q -e . 2>/dev/null
python3 -m pytest tests -v --tb=no -q --override-ini="addopts=" -p no:cacheprovider \
  --ignore=tests/test_twisted.py 2>&1 | \
  python3 /src/unit_tests/parse_results.py --framework pytest
