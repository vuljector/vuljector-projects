#!/bin/bash
cd /src/Twitter4J
./gradlew test --no-daemon 2>&1 | python3 /src/unit_tests/parse_results.py --framework gradle
