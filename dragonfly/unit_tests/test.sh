#!/bin/bash
cd /src/Dragonfly
# Exclude e2e package (requires full environment) and skip network/IPv6-dependent tests
PKGS=$(go list ./... | grep -v '/test/e2e')
go test $PKGS -v -count=1 \
  -skip '^TestPreheat_CreatePreheatRequestsByManifestURL$|^TestExternalIPv6$' \
  2>&1 | python3 /src/unit_tests/parse_results.py --framework gotest
