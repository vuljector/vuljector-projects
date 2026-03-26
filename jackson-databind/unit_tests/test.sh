#!/bin/bash
cd /src/jackson-databind
./mvnw test -pl . 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework maven
