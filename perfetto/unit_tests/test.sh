#!/bin/bash
set -euo pipefail
# Run sqlglot python unit tests from its package root so relative fixture paths resolve
cd /src/perfetto/buildtools/sqlglot
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Skip integration tests that require large datasets or external setup
export SKIP_INTEGRATION=1
# Install minimal Python test deps
python3 -m pip install -q pytest pytz duckdb python-dateutil numpy pandas || true
# Ensure local package is importable
export PYTHONPATH="/src/perfetto/buildtools/sqlglot:${PYTHONPATH:-}"
# Run pytest for the tests directory (no -q so the summary is printed) and pipe through the parser
pytest -ra -o log_cli=false -o console_output_style=classic tests 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest