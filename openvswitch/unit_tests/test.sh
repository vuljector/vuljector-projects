#!/bin/bash
cd /src/openvswitch

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
pip3 install --no-cache-dir pytest netaddr pyparsing >/tmp/test_harness.install.log 2>&1 || true

PYTHONPATH=/src/openvswitch/python python3 -m pytest python/ovs/tests -q 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest