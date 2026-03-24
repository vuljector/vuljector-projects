#!/bin/bash
cd /src/lz4_flex
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cargo test 2>&1 | python3 /src/unit_tests/parse_results.py --framework cargo
