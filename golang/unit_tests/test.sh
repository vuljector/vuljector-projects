#!/bin/bash
export GOROOT_BOOTSTRAP=/root/.go
export PATH="/root/.go/bin:$PATH"

# Try to build the mounted Go from source
cp -r /src/go /tmp/go-build 2>/dev/null
if cd /tmp/go-build/src && bash make.bash >/dev/null 2>&1; then
  export GOROOT=/tmp/go-build
  export PATH="$GOROOT/bin:$PATH"
  export GOTOOLCHAIN=local
  go test fmt encoding/json net/http strings bytes crypto/sha256 \
    crypto/aes crypto/hmac crypto/rand crypto/rsa crypto/tls \
    compress/gzip compress/flate archive/tar archive/zip \
    io io/fs path path/filepath os os/exec \
    sort strconv sync unicode utf8 regexp \
    math math/big math/rand net/url net/mail \
    bufio context errors hash log mime time -v 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gotest
else
  # Fallback: test baked-in stdlib
  export GOROOT=/root/.go
  export PATH="$GOROOT/bin:$PATH"
  export GOTOOLCHAIN=local
  cd $GOROOT/src
  go test fmt encoding/json strings bytes crypto/sha256 \
    crypto/aes crypto/hmac crypto/rand crypto/rsa \
    compress/gzip io sort strconv sync regexp \
    math math/big net/url bufio context errors hash log mime time -v 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework gotest
fi
