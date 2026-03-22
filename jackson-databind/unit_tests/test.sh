#!/bin/bash
cd /src/jackson-databind
./mvnw test -pl . 2>&1 | python3 /src/unit_tests/parse_results.py --framework maven
