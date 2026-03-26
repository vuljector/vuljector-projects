#!/bin/bash
cd /src/spring-data-jpa
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64; export PATH="$JAVA_HOME/bin:$PATH"
GIT_DIR=/dev/null ./mvnw test -B -fn --no-transfer-progress 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework maven
