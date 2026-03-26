#!/bin/bash
cd /src/retry
pip3 install -e . pytest -q 2>/dev/null || pip3 install pytest -q 2>/dev/null || true
python3 -m pytest -v 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
