#!/bin/bash
set -euo pipefail

cd /src/python-ecdsa

python3 -m pip install pytest hypothesis

pytest src/ecdsa 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest