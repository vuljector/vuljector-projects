#!/bin/bash
cd /src/pyasn1
(pip3 install -e '.[test,tests,dev,testing,devel,extras]' pytest -q 2>/dev/null || pip3 install -e . pytest -q 2>/dev/null || pip3 install pytest -q 2>/dev/null) 2>/dev/null || true
python3 -m pytest -v --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
