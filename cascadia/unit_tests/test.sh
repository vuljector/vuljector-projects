#!/bin/bash
cd /src/cascadia
go test ./... -v -count=1 2>&1 | python3 /src/unit_tests/parse_results.py --framework gotest
