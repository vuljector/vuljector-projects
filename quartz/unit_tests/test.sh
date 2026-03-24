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
# Run tests (DB integration tests will fail — that's expected in this environment).
# Parse results from XML reports, excluding the 4 testcontainers-based DB test classes
# that require live MSSQL/MariaDB/Postgres Docker instances.
./gradlew test --no-daemon 2>&1 || true
python3 - <<'PYEOF'
import glob, json, xml.etree.ElementTree as ET

# These classes require a running Docker daemon + real DB images (testcontainers).
EXCLUDE = {
    'MSSQLJdbcStoreTest',
    'MariaDBJdbcStoreTest',
    'PostgresJdbcStoreTest',
    'QuartzMSSQLDatabaseCronTriggerTest',
}

passed = failed = 0
for path in glob.glob('/src/quartz/quartz/build/test-results/test/TEST-*.xml'):
    classname = path.rsplit('TEST-', 1)[-1].replace('.xml', '').rsplit('.', 1)[-1]
    if classname in EXCLUDE:
        continue
    root = ET.parse(path).getroot()
    total    = int(root.get('tests',   0))
    failures = int(root.get('failures', 0))
    errors   = int(root.get('errors',   0))
    skipped  = int(root.get('skipped',  0))
    failed   += failures + errors
    passed   += total - failures - errors - skipped

print(json.dumps({"passed": passed, "failed": failed}))
PYEOF
