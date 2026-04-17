#!/bin/bash
set -euo pipefail
cd /src/leptonica
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Configure if necessary (autotools)
if [ ! -f Makefile ]; then
  ./configure || true
fi

# Build
make -j$(nproc) || true

# Run tests via make check (autotools). Pipe to parser as required.
make check -j$(nproc) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools