#!/bin/bash
set -uo pipefail
cd /src/serenity
# Clear sanitizer flags that break native builds in OSS-Fuzz env
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE || true
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Configure and build a small Lagom host test subset.
mkdir -p /tmp/lagom_build

cmake -GNinja -S /src/serenity/Meta/Lagom -B /tmp/lagom_build -DBUILD_LAGOM=ON >/tmp/serenity_cmake_configure.log 2>&1 || {
    echo "=== cmake configure failed ==="
    tail -50 /tmp/serenity_cmake_configure.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

ninja -C /tmp/lagom_build -j$(nproc) \
    TestLibCoreArgsParser TestLibCoreDateTime \
    TestLibCoreFileWatcher TestLibCorePromise \
    Regex test-invalid-unicode-js test-value-js >/tmp/serenity_ninja_build.log 2>&1 || {
    echo "=== ninja build failed ==="
    tail -80 /tmp/serenity_ninja_build.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

# Run the selected tests via CTest and pipe through the provided parser
cd /tmp/lagom_build || { echo "cd /tmp/lagom_build failed"; printf '{"passed": 0, "failed": -1}\n'; exit 0; }
ctest --output-on-failure -R "TestLibCore|Regex|test-invalid-unicode-js|test-value-js" 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest
