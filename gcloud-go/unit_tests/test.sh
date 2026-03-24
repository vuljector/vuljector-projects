#!/bin/bash
cd /src/google-cloud-go
go test ./... -v -count=1 -skip '^TestIntegration_' 2>&1 | python3 /src/unit_tests/parse_results.py --framework gotest
