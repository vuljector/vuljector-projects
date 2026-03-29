#!/bin/bash
cd /src/jpeg-js
npm install 2>&1 | tail -1
npm test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework jest
