#!/bin/bash
cd /src/fuzzywuzzy
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64; export PATH="$JAVA_HOME/bin:$PATH"; apt-get update -qq 2>/dev/null && apt-get install -y -qq maven >/dev/null 2>&1
mvn test -B -fn --no-transfer-progress 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework maven
