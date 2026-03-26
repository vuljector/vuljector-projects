#!/bin/bash
cd /src/gobgp
go test ./... -v -count=1 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gotest
