#!/bin/bash

# Haven AKS Integration Test - Common Functions Library
# Shared utilities and configuration for integration tests

# Common configuration
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
export EXAMPLES_DIR="${PROJECT_ROOT}/examples"
export TEST_RESULTS_DIR="${SCRIPT_DIR}/test-results"
export REPORT_FILE="${TEST_RESULTS_DIR}/integration-test-report.xml"
export LOG_FILE="${TEST_RESULTS_DIR}/integration-test.log"

# Test metrics (shared across scripts)
export TEST_START_TIME=""
export TEST_END_TIME=""
export TESTS_TOTAL=0
export TESTS_PASSED=0
export TESTS_FAILED=0
export FAILED_TESTS=()
export ALL_EXAMPLES=("minimal" "existing-infrastructure")

# Configuration from environment
export SKIP_DESTROY="${SKIP_DESTROY:-false}"
export DRY_RUN="${DRY_RUN:-false}"
export CI_MODE="${CI_MODE:-false}"

# Colors for output (disabled in CI mode)
if [[ "$CI_MODE" == "true" ]]; then
    export RED=''
    export GREEN=''
    export YELLOW=''
    export BLUE=''
    export NC=''
else
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[1;33m'
    export BLUE='\033[0;34m'
    export NC='\033[0m' # No Color
fi

# Initialize logging
init_logging() {
    mkdir -p "$TEST_RESULTS_DIR"

    # Clear previous results
    > "$LOG_FILE"
    > "$REPORT_FILE"
    > "${TEST_RESULTS_DIR}/failed_tests.txt"

    # Initialize test counters
    export TESTS_TOTAL=0
    export TESTS_PASSED=0
    export TESTS_FAILED=0

    log "INFO" "=== Haven AKS Integration Test Suite ==="
    log "INFO" "Example: ${EXAMPLE_NAME:-unknown}"
    log "INFO" "Dry Run: $DRY_RUN"
    log "INFO" "Skip Destroy: $SKIP_DESTROY"
    log "INFO" "CI Mode: $CI_MODE"
    log "INFO" "Results Directory: $TEST_RESULTS_DIR"
    log "INFO" "========================================"
}

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"

    case "$level" in
        "ERROR")   echo -e "${RED}[ERROR]${NC} $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}[WARNING]${NC} $message" ;;
        "INFO")    echo -e "${BLUE}[INFO]${NC} $message" ;;
    esac
}

# Test execution wrapper
run_test() {
    local test_name="$1"
    local test_script="$2"
    shift 2
    local test_args="$@"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    export TESTS_TOTAL

    log "INFO" "Running test: $test_name"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "INFO" "DRY RUN: Would execute $test_script $test_args"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        export TESTS_PASSED
        write_test_result "$test_name" "passed" "0"
        return 0
    fi

    local start_time=$(date +%s)

    if "$test_script" "$test_args"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "SUCCESS" "Test passed: $test_name (${duration}s)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        export TESTS_PASSED
        write_test_result "$test_name" "passed" "$duration"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log "ERROR" "Test failed: $test_name (${duration}s)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        export TESTS_FAILED
        echo "$test_name" >> "${TEST_RESULTS_DIR}/failed_tests.txt"
        write_test_result "$test_name" "failed" "$duration"
        return 1
    fi
}

# Write individual test result to JUnit XML
write_test_result() {
    local test_name="$1"
    local status="$2"
    local duration="$3"

    local test_case=""
    if [[ "$status" == "passed" ]]; then
        test_case="    <testcase name=\"$test_name\" time=\"$duration\"/>"
    else
        test_case="    <testcase name=\"$test_name\" time=\"$duration\">
      <failure message=\"Test failed: $test_name\"/>
    </testcase>"
    fi

    echo "$test_case" >> "${TEST_RESULTS_DIR}/temp_results.xml"
}

# Cleanup function
cleanup() {
    local exit_code=$?

    log "INFO" "Performing cleanup..."

    # Remove temporary files
    rm -f "${TEST_RESULTS_DIR}/temp_results.xml"

    # Remove terraform plan files
    find "${SCRIPT_DIR}" -name "tfplan" -delete 2>/dev/null || true

    exit $exit_code
}

# Load this library in other scripts
export -f log
export -f run_test
export -f write_test_result
export -f cleanup
export -f init_logging
