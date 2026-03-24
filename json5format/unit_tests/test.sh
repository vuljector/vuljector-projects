#!/bin/bash
cd /src/json5format
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS="--cap-lints allow"
cargo test 2>&1 | python3 /src/unit_tests/parse_results.py --framework cargo
