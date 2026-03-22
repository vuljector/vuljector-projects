#!/bin/bash
cd /src/flask
pip install -e . pytest -q 2>/dev/null || pip install pytest -q 2>/dev/null || true
python -m pytest -v 2>&1 | python3 /src/unit_tests/parse_results.py --framework pytest
