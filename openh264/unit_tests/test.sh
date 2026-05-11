#!/bin/bash
set -uo pipefail

# GTest run is ~2+ minutes; capture full log so the parser always sees the
# final "[  PASSED  ] N tests." line (avoids pipe edge cases under load).
cd /src/openh264
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

log=$(mktemp)
trap 'rm -f "$log"' EXIT

CFLAGS= make -B ENABLE64BIT=Yes BUILDTYPE=Release all plugin test >"$log" 2>&1
rc=$?

cat "$log"
python3 /workspace/run/unit_tests/parse_results.py --framework gtest <"$log"
exit "$rc"