#!/bin/bash
cd /src/commons-lang
# Install Maven 3.9 if needed (container has 3.6)
if ! mvn --version 2>/dev/null | grep -q '3\.[89]'; then
  apt-get update -qq 2>/dev/null && apt-get install -y -qq wget >/dev/null 2>&1
  wget -q https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz -O /tmp/maven.tgz 2>/dev/null
  tar -xzf /tmp/maven.tgz -C /opt/ 2>/dev/null
  export PATH="/opt/apache-maven-3.9.9/bin:$PATH"
fi
mvn test -B -fn --no-transfer-progress 2>&1 | python3 /src/unit_tests/parse_results.py --framework maven
