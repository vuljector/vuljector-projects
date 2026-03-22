#!/bin/bash
cd /src/thrift/lib/rs
cargo test 2>&1 | python3 /src/unit_tests/parse_results.py --framework cargo
