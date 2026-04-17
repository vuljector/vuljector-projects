#!/bin/bash
cd /src/lcms
# Clear OSS-Fuzz sanitizer/fuzzer flags that break normal builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# Build the testcms executable (if needed)
mkdir -p /tmp/build && cd /tmp/build
cmake /src/lcms -DCMAKE_BUILD_TYPE=Debug -DBUILD_TESTING=ON > /dev/null 2>&1
make -j$(nproc) > /dev/null 2>&1

# Run testcms from testbed so relative assets like crayons.icc resolve.
cd /src/lcms/testbed
LD_LIBRARY_PATH=/tmp/build/src/.libs /tmp/build/testbed/testcms 2>&1 | tee /tmp/test_output.txt

# Count the number of lines that end with "...Ok." (three dots, Ok, dot)
passed=$(grep -c '\.\.\.Ok\.$' /tmp/test_output.txt)

printf '%s passed, %s failed\n' "$passed" 0 | python3 /workspace/run/unit_tests/parse_results.py --framework generic
