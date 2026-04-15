#!/bin/bash
cd /src/gpsd || exit 1
# Clear sanitizer flags that break native builds
unset SANITIZER_FLAGS LIB_FUZZING_ENGINE
export CFLAGS="" CXXFLAGS="" LDFLAGS="" RUSTFLAGS=""
export PYTHONPATH="/workspace/run/unit_tests:/src/gpsd:${PYTHONPATH:-}"

(
  set -o pipefail
  echo "Running gpsd unit/integration python tests"
  # Find python test files in tests and devtools
  mapfile -t TEST_FILES < <(find tests devtools -maxdepth 2 -type f -name 'test_*.py' 2>/dev/null | sort)
  if ! python3 - <<'PY' >/dev/null 2>&1
import cairo
PY
  then
    FILTERED=()
    for t in "${TEST_FILES[@]}"; do
      [ "$t" = "tests/test_xgps_deps.py" ] && continue
      FILTERED+=("$t")
    done
    TEST_FILES=("${FILTERED[@]}")
  fi
  passed=0
  failed=0
  if [ ${#TEST_FILES[@]} -eq 0 ]; then
    echo "No python test files found"
    echo "0 passed, 0 failed"
    exit 1
  fi
  for t in "${TEST_FILES[@]}"; do
    echo "=== RUNNING ${t} ==="
    # Run each test file with python3
    python3 "${t}"
    rc=$?
    if [ $rc -eq 0 ]; then
      echo "${t}: OK"
      passed=$((passed+1))
    else
      echo "${t}: FAIL (exit:${rc})"
      failed=$((failed+1))
    fi
  done

  echo "${passed} passed, ${failed} failed"
) 2>&1 | python3 /workspace/run/unit_tests/parse_results.py --framework generic
