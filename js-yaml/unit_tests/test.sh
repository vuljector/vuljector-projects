#!/bin/bash
set -euo pipefail
cd /src/js-yaml
npm install --silent 2>&1 | tail -1
npx mocha --reporter tap test/*.js 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework tap
