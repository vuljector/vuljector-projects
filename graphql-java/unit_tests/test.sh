#!/bin/bash
cd /src/graphql-java
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64; export PATH="$JAVA_HOME/bin:$PATH"
./gradlew test --no-daemon --rerun -PsanitizedBranchName=main 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gradle
