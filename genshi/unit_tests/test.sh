#!/bin/bash
cd /src/genshi
python3 -m pytest genshi -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest