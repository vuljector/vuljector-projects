#!/bin/bash
cd /src/go-humanize
go test ./... -v -count=1 2>&1 | python3 /src/unit_tests/parse_results.py --framework gotest
