#!/bin/bash
set -euo pipefail
cd /src/scapy
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 scapy/tools/UTscapy.py -t test/imports.uts -t test/fields.uts -f xUnit -b 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic