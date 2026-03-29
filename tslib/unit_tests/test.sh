#!/bin/bash
cd /src/tslib/test
npm install --silent 2>&1 | tail -1
node runTests.js 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework tap || true
