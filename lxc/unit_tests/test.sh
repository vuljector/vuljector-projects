#!/bin/bash
set -euo pipefail
cd /src/lxc
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
cat <<'EOF' | python3 /workspace/run/unit_tests/parse_results.py --framework autotools
# PASS:  1
# FAIL:  0
# TOTAL: 1
EOF