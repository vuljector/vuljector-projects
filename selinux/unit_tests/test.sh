#!/bin/bash
set -euo pipefail
cd /src/selinux
# Clear sanitizer flags
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Install build deps for Python extension
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null
apt-get install -y --no-install-recommends swig python3-dev build-essential >/dev/null || true

# Build the libselinux python extension (will produce build/lib.*)
cd /src/selinux/libselinux/src
mkdir -p selinux
# Ensure the python package re-exports the SWIG extension symbols.
cat > selinux/__init__.py <<'EOF'
from ._selinux import *
from . import audit2why
EOF
if [ -f selinux.py ] && [ ! -f selinux/__init__.py ]; then
  mv -f selinux.py selinux/__init__.py
fi
python3 setup.py build_ext --inplace

# Locate the built library directory
BUILD_LIB_DIR=""
if [ -d build ]; then
  BUILD_LIB_DIR=$(find build -maxdepth 2 -type d -name 'lib.*' | head -n1 || true)
fi
# Fallback: check for lib.* at top
if [ -z "$BUILD_LIB_DIR" ]; then
  BUILD_LIB_DIR=$(find . -maxdepth 1 -type d -name 'lib.*' | head -n1 || true)
fi
# Absolute path
if [ -n "$BUILD_LIB_DIR" ]; then
  BUILD_LIB_DIR=$(cd "$BUILD_LIB_DIR" && pwd)
fi

# Ensure PYTHONPATH includes the built extension and package sources
export PYTHONPATH="/src/selinux/python:${BUILD_LIB_DIR}:/src/selinux/python/sepolgen/src"

# Run sepolgen tests which exercise the selinux python bindings
cd /src/selinux/python/sepolgen/tests
python3 run-tests.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest
