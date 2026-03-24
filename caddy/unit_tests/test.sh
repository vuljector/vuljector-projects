#!/bin/bash
cd /src/caddy
# Exclude the integration package (requires network/cert services)
PKGS=$(go list ./... | grep -v '/caddytest/integration')
go test $PKGS -v -count=1 2>&1 | python3 /src/unit_tests/parse_results.py --framework gotest
