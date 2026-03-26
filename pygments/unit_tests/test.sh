#!/usr/bin/env bash
cd /src/pygments
pip install -q -e . pytest wcag-contrast-ratio 2>/dev/null
python3 -m pytest -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
