#!/bin/bash
set -euo pipefail
cd /src/harfbuzz
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
rm -rf /tmp/hb-build
meson setup /tmp/hb-build -Dtests=enabled -Ddocs=disabled -Ddoc_tests=false -Dintrospection=disabled -Dbenchmark=disabled -Dutilities=enabled -Dglib=disabled -Dgobject=disabled -Dcairo=disabled -Dchafa=disabled -Dpng=disabled -Dzlib=disabled -Dicu=disabled -Dfreetype=disabled -Dfontations=disabled -Dgraphite=disabled -Dgraphite2=disabled -Dharfrust=disabled -Dkbts=disabled -Dwasm=disabled >/tmp/meson_setup2.log 2>&1
meson compile -C /tmp/hb-build -j$(nproc) >/tmp/meson_compile2.log 2>&1
meson test -C /tmp/hb-build --print-errorlogs 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework meson