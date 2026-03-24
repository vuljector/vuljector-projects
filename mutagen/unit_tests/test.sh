#!/bin/bash
cd /src/mutagen
pip3 install -q -e . hypothesis pytest 2>/dev/null
python3 -m pytest tests -v --tb=no -q --override-ini="addopts=" -p no:cacheprovider -k "not test_kind" 2>&1 | python3 /src/unit_tests/parse_results.py --framework pytest
