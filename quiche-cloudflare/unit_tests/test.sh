#!/bin/bash
cd /src/quiche
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
apt-get update -qq 2>/dev/null && apt-get install -y -qq libclang-dev pkg-config libfontconfig-dev >/dev/null 2>&1
cargo test 2>&1 | python3 /src/unit_tests/parse_results.py --framework cargo
