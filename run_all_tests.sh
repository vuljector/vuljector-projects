#!/bin/bash
# Rebuild all vuljector Docker images from scratch and run unit tests
set -o pipefail

BASE_DIR="/home/anl31/documents/code/vulinjector/vuljector-projects"
RESULTS_FILE="$BASE_DIR/test_results.txt"
> "$RESULTS_FILE"

PROJECTS=(
  ansible assimp brotli coturn flask golang hcl hdf5
  jackson-databind jsoncpp linkerd2-proxy openssl php pip
  pygments pyodbc quartz quickjs rhai ruby thrift-js
  thrift-rust u-root wamr
)

PASS_COUNT=0
FAIL_COUNT=0

for project in "${PROJECTS[@]}"; do
  PROJECT_DIR="$BASE_DIR/$project"
  SETUP_DIR="$PROJECT_DIR/setup"
  UNIT_TESTS_DIR="$PROJECT_DIR/unit_tests"
  IMAGE_NAME="vuljector-${project}"

  if [ ! -f "$SETUP_DIR/Dockerfile" ]; then
    echo "[$project] SKIP - no Dockerfile"
    echo "$project: SKIP (no Dockerfile)" >> "$RESULTS_FILE"
    continue
  fi

  if [ ! -f "$UNIT_TESTS_DIR/test.sh" ]; then
    echo "[$project] SKIP - no test.sh"
    echo "$project: SKIP (no test.sh)" >> "$RESULTS_FILE"
    continue
  fi

  echo "============================================"
  echo "[$project] Building image..."
  echo "============================================"

  if ! docker build -t "$IMAGE_NAME" -f "$SETUP_DIR/Dockerfile" "$SETUP_DIR" 2>&1 | tail -5; then
    echo "[$project] BUILD FAILED"
    echo "$project: BUILD FAILED" >> "$RESULTS_FILE"
    ((FAIL_COUNT++))
    continue
  fi

  echo "--------------------------------------------"
  echo "[$project] Running tests..."
  echo "--------------------------------------------"

  TEST_OUTPUT=$(docker run --rm \
    -v "$UNIT_TESTS_DIR:/src/unit_tests:ro" \
    "$IMAGE_NAME" \
    bash /src/unit_tests/test.sh 2>&1)

  # Get the last line (JSON summary)
  LAST_LINE=$(echo "$TEST_OUTPUT" | tail -1)
  echo "[$project] Result: $LAST_LINE"
  echo "$project: $LAST_LINE" >> "$RESULTS_FILE"

  # Check if it looks like a valid JSON result
  if echo "$LAST_LINE" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('passed',0)>0 and d.get('failed',0)==0 else 1)" 2>/dev/null; then
    echo "[$project] PASS"
    ((PASS_COUNT++))
  else
    echo "[$project] ISSUE (check results)"
    ((FAIL_COUNT++))
  fi
  echo ""
done

echo "============================================"
echo "SUMMARY: $PASS_COUNT passed, $FAIL_COUNT failed/issues"
echo "============================================"
cat "$RESULTS_FILE"
