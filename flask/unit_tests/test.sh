#!/bin/bash
set -euo pipefail
cd /src/flask
# The OSS-Fuzz image includes a Werkzeug git checkout; its dev tip can disagree with
# Flask's locked release. Pin to the version in Flask's uv.lock so Host validation
# matches tests (e.g. test_bad_environ_raises_bad_request).
pip3 install -q --upgrade "werkzeug==3.1.6"
# Async view tests need asgiref from the async extra; tests group deps from pyproject.
pip3 install -q -e ".[async]" pytest greenlet python-dotenv
python3 -m pytest -v --tb=short 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
