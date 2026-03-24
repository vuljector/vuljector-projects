#!/bin/bash
cd /src/jsoncpp
cmake -B /tmp/build -DCMAKE_BUILD_TYPE=Debug -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF . 2>/dev/null && cmake --build /tmp/build 2>/dev/null && /tmp/build/bin/jsoncpp_test 2>/dev/null | awk '/: OK$/{p++} /: FAILED/{f++} {print} END{print p" passed, "f" failed"}' | python3 /src/unit_tests/parse_results.py --framework generic
