#!/bin/bash
cd /src/ansible
pip3 install -q pytest pytest-mock 2>/dev/null
pip3 install -q . 2>/dev/null
# Full test/units crashes pytest due to os.stat monkeypatch + Python 3.11 compat.
# Run stable subdirectories that produce reliable results.
python3 -m pytest test/units/parsing test/units/executor test/units/galaxy -q --tb=no 2>&1 | python3 /src/unit_tests/parse_results.py --framework pytest
