#!/bin/bash
set -euo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
export CBOR2_BUILD_C_EXTENSION=1
export PATH="/usr/bin:/root/.cargo/bin:$PATH"
cd /src/cbor2
sed -i 's/^license = "MIT"$/license = {text = "MIT"}/' pyproject.toml
python3 -m pip install --no-build-isolation . >/tmp/test_harness_pip.log 2>&1
cd /tmp
python3 -m pytest /src/cbor2/tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest
