#!/bin/bash
set -uo pipefail
cd /src/jsoncpp

cmake -B /tmp/build -DCMAKE_BUILD_TYPE=Debug -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF . >/tmp/jsoncpp_cmake_configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/jsoncpp_cmake_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cmake --build /tmp/build >/tmp/jsoncpp_cmake_build.log 2>&1 || {
    echo "=== cmake --build failed ==="
    tail -80 /tmp/jsoncpp_cmake_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

/tmp/build/bin/jsoncpp_test 2>/dev/null | awk '/: OK$/{p++} /: FAILED/{f++} {print} END{print p" passed, "f" failed"}' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
