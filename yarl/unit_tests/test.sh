#!/bin/bash
set -euo pipefail
cd /src/yarl
python3 -m pip install --no-cache-dir -e . pytest pytest-cov pytest-xdist hypothesis pydantic pytest-codspeed covdefaults
python3 -m pytest 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest