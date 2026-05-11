#!/bin/bash
# OpenVPN: autotools. Unit tests live under tests/unit_tests/openvpn/ and
# are built/run by `make check` there.
set -uo pipefail
cd /src/openvpn || { echo cd failed; printf '{"passed": 0, "failed": -1}\n'; exit 0; }

unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# OSS-Fuzz's build.sh injects `#include "fuzz_header.h"` into several
# openvpn source files. That header doesn't exist in a normal build tree,
# so the unit test build fails with "fuzz_header.h: No such file or
# directory". Revert all tracked source modifications before reconfiguring.
git checkout -- . >/dev/null 2>&1 || true

# openvpn's unit tests use cmocka; ensure it's available on first run.
if ! pkg-config --exists cmocka 2>/dev/null; then
    DEBIAN_FRONTEND=noninteractive apt-get update -qq >/tmp/ovpn_apt.log 2>&1 || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq libcmocka-dev >>/tmp/ovpn_apt.log 2>&1 || {
        echo "=== apt-get install libcmocka-dev failed ==="; tail -40 /tmp/ovpn_apt.log
        printf '{"passed": 0, "failed": -1}\n'; exit 0
    }
fi

# Always reconfigure: we just git-restored sources and possibly installed
# cmocka above, so the cached Makefile / config.status from `compile` is
# stale.
autoreconf -fi >/tmp/ovpn_autoreconf.log 2>&1 || true
./configure --disable-lz4 --disable-plugin-auth-pam --enable-unit-tests \
    >/tmp/ovpn_configure.log 2>&1 || {
    echo "=== ./configure failed ==="; tail -50 /tmp/ovpn_configure.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

make -j"$(nproc)" >/tmp/ovpn_make.log 2>&1 || {
    echo "=== make failed ==="; tail -120 /tmp/ovpn_make.log
    printf '{"passed": 0, "failed": -1}\n'; exit 0
}

out=$(mktemp)
make -C tests/unit_tests/openvpn check >"$out" 2>&1 || true
cat "$out"

cat "$out" | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
