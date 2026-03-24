#!/bin/bash
# Run all project test.sh scripts and report failures and count mismatches
set -o pipefail

BASE_DIR="/home/anl31/documents/code/vulinjector/vuljector-projects"
RESULTS_FILE="$BASE_DIR/full_test_results.txt"
> "$RESULTS_FILE"

PASS=0
FAIL=0
MISMATCH=0
SKIP=0

run_project() {
  local project="$1"
  local expected="$2"
  local PROJECT_DIR="$BASE_DIR/$project"
  local UNIT_TESTS_DIR="$PROJECT_DIR/unit_tests"
  local IMAGE_NAME="vuljector-${project}"

  # Check image exists
  if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
    echo "SKIP|$project|no image|$expected"
    return
  fi

  # Run test with 5min timeout
  local TEST_OUTPUT
  TEST_OUTPUT=$(timeout 1200 docker run --rm \
    -v "$UNIT_TESTS_DIR:/src/unit_tests:ro" \
    "$IMAGE_NAME" \
    bash /src/unit_tests/test.sh 2>&1)
  local exit_code=$?

  if [ $exit_code -eq 124 ]; then
    echo "TIMEOUT|$project|timed out after 1200s|$expected"
    return
  fi

  local LAST_LINE
  LAST_LINE=$(echo "$TEST_OUTPUT" | tail -1)

  # Parse JSON result
  local actual_passed actual_failed
  actual_passed=$(echo "$LAST_LINE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('passed',0))" 2>/dev/null)
  actual_failed=$(echo "$LAST_LINE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('failed',0))" 2>/dev/null)

  if [ -z "$actual_passed" ]; then
    echo "FAIL|$project|invalid output: $LAST_LINE|$expected"
    return
  fi

  if [ "$actual_failed" != "0" ] && [ -n "$actual_failed" ]; then
    if [ "$actual_passed" != "$expected" ]; then
      echo "FAIL+MISMATCH|$project|passed=$actual_passed failed=$actual_failed expected=$expected|$LAST_LINE"
    else
      echo "FAIL|$project|passed=$actual_passed failed=$actual_failed|$LAST_LINE"
    fi
  elif [ "$actual_passed" != "$expected" ]; then
    echo "MISMATCH|$project|passed=$actual_passed expected=$expected|$LAST_LINE"
  else
    echo "PASS|$project|passed=$actual_passed|$LAST_LINE"
  fi
}

export -f run_project
export BASE_DIR

# Get all projects with test.sh and project.json
PROJECTS=()
EXPECTEDS=()
while IFS= read -r -d '' dir; do
  project=$(basename "$dir")
  if [ -f "$dir/unit_tests/test.sh" ] && [ -f "$dir/project.json" ]; then
    expected=$(python3 -c "import json; d=json.load(open('$dir/project.json')); print(d.get('unit_tests', {}).get('expected_passing_count', -1))" 2>/dev/null)
    if [ "$expected" != "-1" ] && [ -n "$expected" ]; then
      PROJECTS+=("$project")
      EXPECTEDS+=("$expected")
    fi
  fi
done < <(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

echo "Found ${#PROJECTS[@]} projects with tests"
echo "Starting parallel test runs (max 8 concurrent)..."

# Run in parallel with xargs, max 8 at a time
printf '%s\n' "${!PROJECTS[@]}" | xargs -P 8 -I{} bash -c '
  idx={}
  projects=('"$(printf '"%s" ' "${PROJECTS[@]}")"')
  expecteds=('"$(printf '"%s" ' "${EXPECTEDS[@]}")"')
  project="${projects[$idx]}"
  expected="${expecteds[$idx]}"
  run_project "$project" "$expected"
' 2>/dev/null | tee "$RESULTS_FILE"

echo ""
echo "============================================"
echo "SUMMARY"
echo "============================================"
PASS=$(grep -c "^PASS|" "$RESULTS_FILE" 2>/dev/null || echo 0)
FAIL=$(grep -c "^FAIL|" "$RESULTS_FILE" 2>/dev/null || echo 0)
MISMATCH=$(grep -c "^MISMATCH|" "$RESULTS_FILE" 2>/dev/null || echo 0)
FAIL_MISMATCH=$(grep -c "^FAIL+MISMATCH|" "$RESULTS_FILE" 2>/dev/null || echo 0)
SKIP=$(grep -c "^SKIP|" "$RESULTS_FILE" 2>/dev/null || echo 0)
TIMEOUT=$(grep -c "^TIMEOUT|" "$RESULTS_FILE" 2>/dev/null || echo 0)

echo "PASS:         $PASS"
echo "FAIL:         $FAIL"
echo "MISMATCH:     $MISMATCH"
echo "FAIL+MISMATCH:$FAIL_MISMATCH"
echo "SKIP:         $SKIP"
echo "TIMEOUT:      $TIMEOUT"