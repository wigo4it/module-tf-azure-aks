#!/bin/bash
# Integration test — shared config, logging, and JUnit helpers.
# Source this file; do not execute it directly.

export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
export EXAMPLES_DIR="${PROJECT_ROOT}/examples"
export TEST_RESULTS_DIR="${SCRIPT_DIR}/test-results"
export REPORT_FILE="${TEST_RESULTS_DIR}/integration-test-report.xml"
export LOG_FILE="${TEST_RESULTS_DIR}/integration-test.log"
export ALL_EXAMPLES=("minimal" "existing-infrastructure")

# Runtime flags (override via env)
export SKIP_DESTROY="${SKIP_DESTROY:-false}"
export DRY_RUN="${DRY_RUN:-false}"
export CI_MODE="${CI_MODE:-false}"

# Counters
export TESTS_TOTAL=0 TESTS_PASSED=0 TESTS_FAILED=0

# Colors (suppressed in CI mode)
if [[ "$CI_MODE" != "true" ]]; then
  export RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m'
else
  export RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

log() {
  local level="$1"; shift
  local ts; ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] [$level] $*" | tee -a "$LOG_FILE"
  case "$level" in
    ERROR)   echo -e "${RED}[ERROR]${NC} $*" ;;
    SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $*" ;;
    WARNING) echo -e "${YELLOW}[WARNING]${NC} $*" ;;
    INFO)    echo -e "${BLUE}[INFO]${NC} $*" ;;
  esac
}

# Load .env when running the existing-infrastructure example.
# Call with the directory that contains .env (defaults to current dir).
load_env() {
  local dir="${1:-.}"
  if [[ "$EXAMPLE_NAME" == "existing-infrastructure" && -f "$dir/.env" ]]; then
    log "INFO" "Loading $dir/.env"
    set -a; source "$dir/.env"; set +a
  fi
}

# Execute one named test step; honours DRY_RUN.
# Usage: run_step "Label" <function_or_command> [args…]
run_step() {
  local name="$1"; shift
  TESTS_TOTAL=$((TESTS_TOTAL + 1))
  log "INFO" "▶ $name"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "INFO" "DRY_RUN: skipping $name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    _xml_case "$name" 0
    return 0
  fi

  local t0; t0=$(date +%s)
  if "$@"; then
    local dur=$(( $(date +%s) - t0 ))
    log "SUCCESS" "✓ $name (${dur}s)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
    _xml_case "$name" "$dur"
    return 0
  else
    local dur=$(( $(date +%s) - t0 ))
    log "ERROR" "✗ $name (${dur}s)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    _xml_case "$name" "$dur" "failed"
    echo "$name" >> "${TEST_RESULTS_DIR}/failed_tests.txt"
    return 1
  fi
}

_xml_case() {
  local name="$1" dur="$2" status="${3:-}"
  if [[ -z "$status" ]]; then
    echo "    <testcase name=\"$name\" time=\"$dur\"/>" >> "${TEST_RESULTS_DIR}/tmp.xml"
  else
    printf '    <testcase name="%s" time="%s">\n      <failure message="Test failed: %s"/>\n    </testcase>\n' \
      "$name" "$dur" "$name" >> "${TEST_RESULTS_DIR}/tmp.xml"
  fi
}

init_results() {
  mkdir -p "$TEST_RESULTS_DIR"
  : > "$LOG_FILE" > "$REPORT_FILE" > "${TEST_RESULTS_DIR}/failed_tests.txt" > "${TEST_RESULTS_DIR}/tmp.xml"
  TESTS_TOTAL=0; TESTS_PASSED=0; TESTS_FAILED=0
  export TEST_START_TIME; TEST_START_TIME=$(date +%s)
  log "INFO" "=== Haven AKS Integration Test Suite ==="
  log "INFO" "Example: ${EXAMPLE_NAME:-all}  DRY_RUN=$DRY_RUN  SKIP_DESTROY=$SKIP_DESTROY  CI_MODE=$CI_MODE"
}

write_report() {
  local suite="${1:-unknown}"
  local total_time=$(( $(date +%s) - TEST_START_TIME ))

  cat > "$REPORT_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Haven AKS Integration Tests" tests="$TESTS_TOTAL" failures="$TESTS_FAILED" time="$total_time">
  <testsuite name="$suite" tests="$TESTS_TOTAL" failures="$TESTS_FAILED" time="$total_time">
$(cat "${TEST_RESULTS_DIR}/tmp.xml" 2>/dev/null)
  </testsuite>
</testsuites>
EOF

  {
    echo "Haven AKS Integration Test Summary"
    echo "=================================="
    echo "Suite:    $suite"
    echo "Duration: ${total_time}s"
    echo "Total:    $TESTS_TOTAL  Passed: $TESTS_PASSED  Failed: $TESTS_FAILED"
    [[ $TESTS_FAILED -gt 0 ]] && { echo ""; echo "Failed tests:"; cat "${TEST_RESULTS_DIR}/failed_tests.txt"; }
    echo ""
    echo "Status: $( [[ $TESTS_FAILED -eq 0 ]] && echo SUCCESS || echo FAILURE )"
  } | tee "${TEST_RESULTS_DIR}/summary.txt"

  rm -f "${TEST_RESULTS_DIR}/tmp.xml"
}

export -f log load_env run_step _xml_case init_results write_report
