#!/bin/bash
set -euo pipefail
cd /src/zopfli
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
make -j$(nproc)
cd go
CGO_CFLAGS="-I/src/zopfli/src/zopfli -I/src/zopfli/src/zopflipng" CGO_LDFLAGS="-L/src/zopfli -lzopfli -lzopflipng -lm -lstdc++" go test ./... -v -count=1 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gotest