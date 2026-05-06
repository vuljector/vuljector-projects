#!/bin/bash
set -euo pipefail
cd /src/selinux
# Clear sanitizer flags
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Install build deps for Python extension
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null
apt-get install -y --no-install-recommends swig python3-dev build-essential selinux-policy-dev libpcre3-dev >/dev/null || true

# Build a native libselinux shared library that matches the Python extension.
make -C /src/selinux/libselinux/src clean >/dev/null 2>&1 || true
make -C /src/selinux/libselinux/src PCRE_LDLIBS=-lpcre -j4 >/dev/null

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

# Ensure PYTHONPATH includes the built extension and package sources.
# The in-place build puts .so files into /src/selinux/libselinux/src/selinux/, so
# include that parent dir so Python finds the selinux package with __init__.py.
LIBLESELINUX_SRC="/src/selinux/libselinux/src"
export PYTHONPATH="/src/selinux/python:${LIBLESELINUX_SRC}:${BUILD_LIB_DIR}:/src/selinux/python/sepolgen/src"
# Use the locally built libselinux (newer than system 3.0) so _selinux.so loads correctly
export LD_LIBRARY_PATH="${LIBLESELINUX_SRC}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

# Run sepolgen tests which exercise the selinux python bindings
cd /src/selinux/python/sepolgen/tests
python3 run-tests.py 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework unittest
