#!/bin/bash
set -uo pipefail
cp -r /src/coturn /tmp/coturn-build
cd /tmp/coturn-build || { echo "cd /tmp/coturn-build failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }
rm -rf .git build
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS=""
git init . >/dev/null 2>&1
git add -A >/dev/null 2>&1
git -c user.email="x@x" -c user.name="x" commit -m "init" >/dev/null 2>&1
mkdir build
cd build || { echo "cd build failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

cmake .. -DCMAKE_BUILD_TYPE=Debug -Wno-dev >/tmp/coturn_cmake_configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/coturn_cmake_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cmake --build . --target turnutils_rfc5769check -j$(nproc) >/tmp/coturn_cmake_build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/coturn_cmake_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

(
  OUTPUT=$(./bin/turnutils_rfc5769check 2>&1)
  echo "$OUTPUT"
  PASS=$(echo "$OUTPUT" | grep -c -E "success|:OK" || true)
  FAIL=$(echo "$OUTPUT" | grep -c "failure" || true)
  TOTAL=$((PASS + FAIL))
  echo "${FAIL} tests failed out of ${TOTAL}"
) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
