#!/bin/bash
cd /src/swagger-core
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64; export PATH="$JAVA_HOME/bin:$PATH"
GIT_DIR=/dev/null ./mvnw test -B -fn --no-transfer-progress 2>&1 | python3 /src/unit_tests/parse_results.py --framework maven
