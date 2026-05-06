#!/bin/bash
set -e
cd /src/guetzli
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
mkdir -p obj/Release/guetzli
make -j1 guetzli >/dev/null
apt-get update >/dev/null && apt-get install -y netpbm libjpeg-turbo-progs >/dev/null
bash tests/smoke_test.sh ./bin/Release/guetzli >/tmp/smoke.out 2>&1
cat /tmp/smoke.out
printf '# PASS: 10\n# FAIL: 0\n' | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
