#!/bin/bash
cd /tmp
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install -e /src/h5py >/tmp/pip_install.log 2>&1
python3 -m pytest /src/h5py/h5py/tests -v 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest