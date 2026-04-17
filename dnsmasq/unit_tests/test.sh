#!/bin/bash
set -e
cd /src/dnsmasq
# Clear OSS-Fuzz sanitizer flags which break native builds/executables
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

PARSE_RESULTS="python3 /workspace/run/unit_tests/parse_results.py --framework generic"
UNIT_TEST_SRC=/workspace/run/unit_tests/test_dnsmasq.c
UNIT_TEST_BIN=/tmp/dnsmasq_unit_tests

{
  # ── test 1: config syntax check ────────────────────────────────────────────
  if ./src/dnsmasq --test >/dev/null 2>&1; then
    echo "PASS: dnsmasq syntax check OK"
    echo "1 passed"
  else
    echo "FAIL: dnsmasq syntax check FAILED"
    echo "0 passed"
    echo "1 failed"
  fi

  # ── tests 2-N: C unit tests against libdnsmasq.a ───────────────────────────
  if gcc "$UNIT_TEST_SRC" \
         -I/src/dnsmasq/src \
         /src/dnsmasq/src/libdnsmasq.a \
         -lm -lpthread \
         -o "$UNIT_TEST_BIN" 2>/dev/null; then
    "$UNIT_TEST_BIN" || true
  else
    echo "FAIL: could not compile C unit tests"
    echo "0 passed"
    echo "1 failed"
  fi

} | $PARSE_RESULTS
