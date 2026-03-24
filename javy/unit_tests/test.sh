#!/bin/bash
cd /src/javy
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
cargo test --lib --workspace 2>&1 | python3 /src/unit_tests/parse_results.py --framework cargo
