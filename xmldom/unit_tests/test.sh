#!/bin/bash
cd /src/xmldom
npm install 2>&1 | tail -1
npm test 2>&1 | python3 /src/unit_tests/parse_results.py --framework jest
