#!/bin/bash
set -e
cd /src/pypdf
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
python3 -m pytest -c /dev/null tests -q -o addopts= -o markers='slow: Test which require more than a second' -o markers='samples: Tests which use files from https://github.com/py-pdf/sample-files' -o markers='enable_socket: Tests which need to download files' -o markers='timeout: test timeout marker' 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework pytest