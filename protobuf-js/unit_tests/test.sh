#!/bin/bash
set -euo pipefail
cd /src/protobuf.js
npm install --silent 2>&1 | tail -1
npm run test:sources 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework tap
