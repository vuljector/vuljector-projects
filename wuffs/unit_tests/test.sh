#!/bin/bash
cd /src/wuffs
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS="" && export PATH=/usr/local/go/bin:$PATH

go test -v -count=1 ./... 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gotest