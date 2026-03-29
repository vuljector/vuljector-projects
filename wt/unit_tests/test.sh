#!/bin/bash
set -euo pipefail
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cd /src/wt
rm -rf /tmp/build
mkdir -p /tmp/build
cd /tmp/build
cmake /src/wt -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON -DENABLE_LIBWTTEST=ON
cmake --build . -j"$(nproc)"
set +o pipefail
./test/test.wt 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework boost
TEST_STATUS=$?
set -o pipefail
if [ $TEST_STATUS -ne 0 ]; then
  echo "Tests failed with status $TEST_STATUS" >&2
fi
exit 0