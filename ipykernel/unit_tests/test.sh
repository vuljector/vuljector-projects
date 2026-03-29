#!/bin/bash
set -euo pipefail
cd /src/ipykernel
pip3 install -q pytest pytest-asyncio pytest-cov pytest-timeout || true
python3 -m pytest tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest