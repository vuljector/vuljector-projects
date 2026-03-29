#!/bin/bash
cd /src/pyparsing
pip3 install pytest railroad jinja2 >/tmp/pyparsing_pytest_install.log 2>&1 || true
python3 -m pytest tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest