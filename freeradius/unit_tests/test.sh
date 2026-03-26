#!/bin/bash
cd /src/freeradius-server || exit 1
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""

# If the build/test binaries are missing, configure and build
if [ ! -d build/bin/local ] || [ -z "$(ls -A build/bin/local 2>/dev/null)" ]; then
  ./configure || true
  make -j$(nproc) || true
fi

# Run unit test binaries in build/bin/local, count pass/fail by exit code
(
  passed=0
  failed=0
  TEST_DIR="build/bin/local"
  if [ -d "$TEST_DIR" ]; then
    for f in "$TEST_DIR"/*; do
      [ -f "$f" ] || continue
      [ -x "$f" ] || continue
      name="$(basename "$f")"
      echo "==== RUNNING: $name ===="
      # Run each test with a timeout to avoid hangs
      timeout 60 "$f"
      rc=$?
      if [ $rc -eq 0 ]; then
        echo "--- RESULT: PASS: $name"
        passed=$((passed+1))
      else
        echo "--- RESULT: FAIL: $name (exit $rc)"
        failed=$((failed+1))
      fi
    done
  else
    echo "No test directory: $TEST_DIR" >&2
  fi
  echo "$passed passed, $failed failed"
) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic