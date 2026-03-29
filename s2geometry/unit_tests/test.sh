#!/bin/bash
set -euo pipefail
cd /src/s2geometry
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
mkdir -p /tmp/absl_compat/absl/base/internal
cat > /tmp/absl_compat/absl/base/internal/throw_delegate.h <<'EOF'
#pragma once
#include "absl/base/throw_delegate.h"
namespace absl {
namespace base_internal {
using ::absl::ThrowStdLogicError;
using ::absl::ThrowStdOutOfRange;
using ::absl::ThrowStdInvalidArgument;
using ::absl::ThrowStdDomainError;
using ::absl::ThrowStdLengthError;
}  // namespace base_internal
}  // namespace absl
EOF
export CPATH="/tmp/absl_compat:/usr/local/include:${CPATH:-}"
export CPLUS_INCLUDE_PATH="/tmp/absl_compat:/usr/local/include:${CPLUS_INCLUDE_PATH:-}"
cd build
make -j$(nproc)
ctest --output-on-failure -j$(nproc) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework ctest