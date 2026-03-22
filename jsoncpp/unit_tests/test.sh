#!/bin/bash
cd /src/jsoncpp
cmake -B /tmp/build -DCMAKE_BUILD_TYPE=Debug . && cmake --build /tmp/build && ctest --test-dir /tmp/build -V 2>&1 | python3 /src/unit_tests/parse_results.py --framework ctest
