#!/bin/bash
set -euo pipefail
cd /src/httpx
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS="" PYTEST_DISABLE_PLUGIN_AUTOLOAD=1
python3 -m pytest tests -v --tb=short -W ignore::trio.TrioDeprecationWarning --override-ini='filterwarnings=error' --override-ini='filterwarnings=ignore: trio.MultiError is deprecated since Trio 0.22.0:trio.TrioDeprecationWarning' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest