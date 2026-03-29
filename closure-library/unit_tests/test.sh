#!/bin/bash
set -euo pipefail
cd /src/closure-library/closure-deps
npm install --silent 2>&1 | tail -1
npm test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework jasmine
