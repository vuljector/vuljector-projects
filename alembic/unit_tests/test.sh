#!/bin/bash
set -euo pipefail
cd /src/alembic/python/PyAlembic/Tests
python3 -m unittest -v testIterators 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest