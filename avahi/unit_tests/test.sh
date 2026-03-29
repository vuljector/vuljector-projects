#!/bin/bash
set -euo pipefail
cd /src/avahi
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make -C avahi-common -j$(nproc) strlst-test domain-test >/dev/null
{
  echo '# TOTAL: 2'
  echo '# PASS:  0'
  echo '# FAIL:  0'
  ./avahi-common/strlst-test >/dev/null && echo '# PASS:  1' || echo '# FAIL:  1'
  ./avahi-common/domain-test >/dev/null && echo '# PASS:  1' || echo '# FAIL:  1'
} 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework autotools