#!/bin/bash
set -eu

cd /src/opensc

# Build the tools if not already built
if [ ! -f src/tools/opensc-tool ]; then
    # Build dependencies
    if [ ! -d /tmp/openpace ]; then
        git clone https://github.com/frankmorgner/openpace.git /tmp/openpace 2>/dev/null || true
        if [ -d /tmp/openpace ]; then
            cd /tmp/openpace
            autoreconf --verbose --install >/dev/null 2>&1 || true
            ./configure --enable-static --disable-shared --prefix=/usr >/dev/null 2>&1 || true
            make >/dev/null 2>&1 || true
            make install >/dev/null 2>&1 || true
        fi
    fi

    # Build opensc tools
    cd /src/opensc
    if [ ! -f configure ]; then
        ./bootstrap >/dev/null 2>&1 || true
    fi
    ./configure --disable-optimization --enable-static --disable-shared --disable-pcsc --enable-ctapi >/dev/null 2>&1 || true
    make -j4 >/dev/null 2>&1 || true
fi

cd /src/opensc

passed=0
failed=0

run() {
  if src/tools/opensc-tool "$@" >/dev/null 2>&1; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
  fi
}

run --version
run -i
run --list-readers
run --list-drivers
run --get-conf-entry "app:default:debug"

printf '%s passed, %s failed\n' "$passed" "$failed" | python3 /workspace/run/unit_tests/parse_results.py
