#!/bin/bash
cd /src/thrift
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
GOTOOLCHAIN=local /usr/local/go/bin/go test -count=1 -v ./lib/go/thrift/... 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gotest