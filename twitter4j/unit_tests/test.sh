#!/bin/bash
cd /src/Twitter4J
./gradlew test --no-daemon 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gradle
