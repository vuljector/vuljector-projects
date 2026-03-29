#!/bin/bash
cd /src/python3-openid
python3 -m unittest openid.test.test_suite 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest