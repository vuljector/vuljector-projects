#!/bin/bash
set -euo pipefail
cd /src/toolbelt
python3 -m pip install --upgrade pip
pip3 install -e . pytest betamax
python3 -m pytest tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest