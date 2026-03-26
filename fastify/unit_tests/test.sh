#!/bin/bash
set -euo pipefail
cd /src/fastify
# Clear sanitizer flags per OSS-Fuzz requirements
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
# Install Node 20 via NodeSource if necessary
NEEDED=false
if command -v node >/dev/null 2>&1; then
  V=$(node -v | sed 's/^v//')
  MAJOR=${V%%.*}
  if [ "$MAJOR" -ge 20 ]; then
    NEEDED=false
  else
    NEEDED=true
  fi
else
  NEEDED=true
fi
if [ "$NEEDED" = true ]; then
  apt-get update -y && apt-get install -y curl ca-certificates gnupg
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
fi
# Prefer /usr/bin over /usr/local/bin to use apt-installed node
export PATH="/usr/bin:/bin:$PATH"
hash -r || true
# Show node/npm versions
node -v || true
npm -v || true
# Run unit tests via npm; borp emits TAP which we parse with the 'tap' framework
npm run unit --silent --no-audit --no-fund 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework tap