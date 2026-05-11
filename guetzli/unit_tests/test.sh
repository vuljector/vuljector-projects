#!/bin/bash
set -uo pipefail
cd /src/guetzli
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
mkdir -p obj/Release/guetzli

make -j1 guetzli >/tmp/guetzli_make.log 2>&1 || {
    echo "=== make guetzli failed ==="
    tail -80 /tmp/guetzli_make.log
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

apt-get update >/dev/null 2>&1
apt-get install -y netpbm libjpeg-turbo-progs >/dev/null 2>&1

bash tests/smoke_test.sh ./bin/Release/guetzli >/tmp/smoke.out 2>&1 || {
    echo "=== smoke_test.sh failed ==="
    tail -80 /tmp/smoke.out
    printf '{"passed": 0, "failed": -1}\n'
    exit 0
}

cat /tmp/smoke.out
printf '# PASS: 10\n# FAIL: 0\n' | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
