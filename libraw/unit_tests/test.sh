#!/bin/bash
set +e
cd /src/libraw
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE && export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
tmpdir="$(mktemp -d)"
cat >"$tmpdir/test.cpp" <<'EOF'
#include <iostream>
#include <libraw/libraw.h>

int main() {
  int passed = 0;
  int failed = 0;
  const char *ver = libraw_version();
  if (ver && *ver) passed++; else failed++;
  if (libraw_versionNumber() > 0) passed++; else failed++;
  if (libraw_cameraCount() > 0) passed++; else failed++;
  std::cout << passed << " passed, " << failed << " failed\n";
  return failed ? 1 : 0;
}
EOF
c++ -I. -I./libraw "$tmpdir/test.cpp" -L./lib/.libs -lraw -o "$tmpdir/test"
LD_LIBRARY_PATH=./lib/.libs "$tmpdir/test" 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic
