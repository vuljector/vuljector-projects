#!/bin/bash
# h2o: cmake. The unit test suite is the `check` make target on the cmake build
# tree; runs t/00unit/* C unit tests built with picotls + h2o internals.
set -uo pipefail
cd /src/h2o || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# build.sh ran `cmake -DBUILD_FUZZER=ON -DOSS_FUZZ=ON .` in /src/h2o (in-tree).
# Reuse it but build the `check` target.
if [ ! -f Makefile ]; then
    cmake -DBUILD_FUZZER=ON -DOSS_FUZZ=ON . >/tmp/h2o_cfg.log 2>&1 || {
        echo "=== cmake configure failed ==="; tail -80 /tmp/h2o_cfg.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

# Build the evloop unit-test binary. The cmake target name uses dashes
# (`t-00unit-evloop.t`) but the produced executable lives at `t/00unit.evloop.t`.
# The top-level `check` target runs the Perl integration suite, which needs
# extra Perl modules / network we don't bring in.
make -j"$(nproc)" t-00unit-evloop.t >/tmp/h2o_build.log 2>&1 || {
    echo "=== make t-00unit-evloop.t failed ==="; tail -120 /tmp/h2o_build.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

# h2o unit tests use TAP: "1..N" plan + "ok X - <desc>" / "not ok X - <desc>".
out=$(mktemp)
./t-00unit-evloop.t >"$out" 2>&1 || true
cat "$out"

python3 - "$out" <<'PY' | python3 /workspace/run/unit_tests/parse_results.py --framework generic
import re, sys
text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
ok = sum(1 for _ in re.finditer(r"^ok\s+\d+", text, re.MULTILINE))
nok = sum(1 for _ in re.finditer(r"^not ok\s+\d+", text, re.MULTILINE))
print(f"{ok} passed, {nok} failed")
PY
