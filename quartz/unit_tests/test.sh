#!/bin/bash
cd /src/quartz
# The Dockerfile bundles JDK 11.0.0.1 which can't do modern TLS.
# Install Adoptium JDK 11 (newer patch with TLS 1.3 support).
apt-get update -qq 2>/dev/null
apt-get install -y -qq wget 2>/dev/null
wget -q https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.25%2B9/OpenJDK11U-jdk_x64_linux_hotspot_11.0.25_9.tar.gz -O /tmp/jdk11.tar.gz 2>/dev/null
mkdir -p /opt/jdk11 && tar xzf /tmp/jdk11.tar.gz -C /opt/jdk11 --strip-components=1
export JAVA_HOME=/opt/jdk11
export PATH="$JAVA_HOME/bin:$PATH"
java -version 2>&1
./gradlew test --no-daemon 2>&1 | python3 /src/unit_tests/parse_results.py --framework gradle
