#!/bin/bash
cd /src/rhai
cargo test 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework cargo
