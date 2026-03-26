#!/bin/bash
cd /src/php-src
if [ ! -f configure ]; then ./buildconf --force 2>&1 | tail -1; fi
./configure --disable-all --enable-cli 2>&1 | tail -1
make -j$(nproc) 2>&1 | tail -1
TEST_PHP_ARGS="-q" make test TESTS="tests/" 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework phptest
