#!/bin/bash
cd /src/pyodbc
apt-get update -qq 2>/dev/null && apt-get install -y -qq unixodbc-dev 2>/dev/null
pip3 install -q pytest 2>/dev/null
pip3 install -q -e . 2>/dev/null
python3 -m pytest tests/ -q --tb=no -k "not connect" 2>&1 | python3 /src/unit_tests/parse_results.py --framework pytest
