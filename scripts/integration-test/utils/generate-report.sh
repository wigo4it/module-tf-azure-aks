#!/bin/bash

# Haven AKS Integration Test - Report Generator
# Generates GitLab-compatible JUnit XML reports and summary

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Generate GitLab-compatible JUnit XML report
generate_report() {
    log "INFO" "Generating test report..."

    local total_time=$((TEST_END_TIME - TEST_START_TIME))
    local example_name="${1:-unknown}"

    # Count actual test cases from temp file
    local actual_tests=0
    local actual_passed=0
    local actual_failed=0

    if [[ -f "${TEST_RESULTS_DIR}/temp_results.xml" ]]; then
        actual_tests=$(grep -c "<testcase" "${TEST_RESULTS_DIR}/temp_results.xml" 2>/dev/null || echo "0")
        actual_passed=$(grep "<testcase" "${TEST_RESULTS_DIR}/temp_results.xml" 2>/dev/null | grep -c -v "<failure" || echo "0")
        actual_failed=$(grep -c "<failure" "${TEST_RESULTS_DIR}/temp_results.xml" 2>/dev/null || echo "0")
    fi

    # Use actual counts if available, otherwise fall back to environment variables
    # Strip whitespace from variables and ensure they're valid numbers
    local final_tests=$(echo "${actual_tests:-${TESTS_TOTAL:-0}}" | tr -d '\n\r\t ' | grep -E '^[0-9]+$' || echo "0")
    local final_passed=$(echo "${actual_passed:-${TESTS_PASSED:-0}}" | tr -d '\n\r\t ' | grep -E '^[0-9]+$' || echo "0")
    local final_failed=$(echo "${actual_failed:-${TESTS_FAILED:-0}}" | tr -d '\n\r\t ' | grep -E '^[0-9]+$' || echo "0")

    cat > "$REPORT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Haven AKS Integration Tests" tests="$final_tests" failures="$final_failed" time="$total_time">
  <testsuite name="$example_name" tests="$final_tests" failures="$final_failed" time="$total_time">
$(cat "${TEST_RESULTS_DIR}/temp_results.xml" 2>/dev/null || echo "")
  </testsuite>
</testsuites>
EOF

    # Create summary report
    {
        echo "Haven AKS Integration Test Summary"
        echo "=================================="
        echo ""
        echo "Example: $example_name"
        echo "Duration: ${total_time}s"
        echo "Total Tests: $final_tests"
        echo "Passed: $final_passed"
        echo "Failed: $final_failed"
        echo ""

        if [[ $final_failed -gt 0 ]]; then
            echo "Failed Tests:"
            if [[ -f "${TEST_RESULTS_DIR}/failed_tests.txt" ]]; then
                cat "${TEST_RESULTS_DIR}/failed_tests.txt"
            fi
            echo ""
        fi

        if [[ $final_failed -eq 0 ]]; then
            echo "Status: SUCCESS"
        else
            echo "Status: FAILURE"
        fi
    } > "${TEST_RESULTS_DIR}/summary.txt"

    log "SUCCESS" "Test report generated: $REPORT_FILE"

    # Display summary
    cat "${TEST_RESULTS_DIR}/summary.txt"
}

# Main execution
main() {
    local example_name="${1:-unknown}"
    export EXAMPLE_NAME="$example_name"

    generate_report "$example_name"
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
