#!/bin/bash
set -e
cp -r /src/coturn /tmp/coturn-build
cd /tmp/coturn-build
rm -rf .git build
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
git init . >/dev/null 2>&1
git add -A >/dev/null 2>&1
git -c user.email="x@x" -c user.name="x" commit -m "init" >/dev/null 2>&1
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug -Wno-dev >/dev/null 2>&1
cmake --build . --target turnutils_rfc5769check -j$(nproc) 2>&1 | tail -1
(
  OUTPUT=$(./bin/turnutils_rfc5769check 2>&1)
  echo "$OUTPUT"
  PASS=$(echo "$OUTPUT" | grep -c -E "success|:OK" || true)
  FAIL=$(echo "$OUTPUT" | grep -c "failure" || true)
  TOTAL=$((PASS + FAIL))
  echo "${FAIL} tests failed out of ${TOTAL}"
) 2>&1 | python3 /src/unit_tests/parse_results.py --framework ctest
