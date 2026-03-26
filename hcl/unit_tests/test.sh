#!/bin/bash
cd /src/hcl
go test ./... -v 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gotest
