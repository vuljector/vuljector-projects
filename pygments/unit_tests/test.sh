#!/usr/bin/env bash
set -euo pipefail

# Optional: install test dependencies if a requirements file exists
if [ -f /src/pygments/requirements-dev.txt ]; then
  python3 -m pip install -r /src/pygments/requirements-dev.txt
fi

# Build the project if a setup.py exists (typical for Python projects)
cd /src/pygments
if [ -f setup.py ]; then
  echo "Building and installing /src/pygments..."
  python3 setup.py build || true
  python3 -m pip install -e . || true
fi

# Ensure pytest is available
if ! command -v pytest >/dev/null 2>&1; then
  echo "Installing pytest..."
  python3 -m pip install pytest
fi

# Run tests and pipe output to the pre-existing parser
pytest -q 2>&1 | python3 /src/unit_tests/parse_results.py --framework pytest
