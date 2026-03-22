#!/bin/bash
cd /src/linkerd2-proxy
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Run tests only on core library crates, skip integration-heavy ones
cargo test -p linkerd-app-core -p linkerd-proxy-http -p linkerd-tls 2>&1 | python3 /src/unit_tests/parse_results.py --framework cargo
