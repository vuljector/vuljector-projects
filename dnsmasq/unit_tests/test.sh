#!/bin/bash
set -e
cd /src/dnsmasq
# Clear OSS-Fuzz sanitizer flags which break native builds/executables
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

if ./src/dnsmasq --test >/dev/null 2>&1; then
  printf '%s\n' "dnsmasq: syntax check OK." "1 passed"
else
  printf '%s\n' "dnsmasq: syntax check FAILED." "0 passed" "1 failed"
fi | python3 /workspace/run/unit_tests/parse_results.py --framework generic
