#!/bin/bash

# Haven AKS Integration Test - Test Orchestrator
# Orchestrates the execution of all integration tests according to single responsibility principle

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# Test script paths
TESTS_DIR="${SCRIPT_DIR}/tests"
UTILS_DIR="${SCRIPT_DIR}/utils"

# Test execution orchestrator
run_example_tests() {
    local example="$1"
    local original_example="${EXAMPLE_NAME:-minimal}"

    log "INFO" "=== Starting tests for example: $example ==="
    export EXAMPLE_NAME="$example"

    # Check if example directory exists
    if [[ ! -d "${EXAMPLES_DIR}/${example}" ]]; then
        log "ERROR" "Example directory not found: ${EXAMPLES_DIR}/${example}"
        export EXAMPLE_NAME="$original_example"
        return 1
    fi

    # Setup test infrastructure for existing-infrastructure example
    if [[ "$example" == "existing-infrastructure" ]]; then
        run_test "${example}_Setup_Test_Infrastructure" "${TESTS_DIR}/setup-test-infrastructure.sh" "$example" || return 1
    fi

    # Execute test suite for this example
    run_test "${example}_Prerequisites_Check" "${TESTS_DIR}/check-prerequisites.sh" "$example" || return 1
    run_test "${example}_Terraform_Validation" "${TESTS_DIR}/validate-terraform.sh" "$example" || return 1
    run_test "${example}_Terraform_Plan" "${TESTS_DIR}/terraform-plan.sh" "$example" || return 1
    run_test "${example}_Infrastructure_Deployment" "${TESTS_DIR}/deploy-infrastructure.sh" "$example" || return 1
    run_test "${example}_Kubectl_Configuration" "${TESTS_DIR}/configure-kubectl.sh" "$example" || return 1
    run_test "${example}_AKS_Connectivity" "${TESTS_DIR}/test-aks-connectivity.sh" "$example" || return 1
    run_test "${example}_Kubernetes_Operations" "${TESTS_DIR}/test-kubernetes-operations.sh" "$example" || return 1
    run_test "${example}_Monitoring_Integration" "${TESTS_DIR}/test-monitoring.sh" "$example"
    run_test "${example}_DNS_Configuration" "${TESTS_DIR}/test-dns-configuration.sh" "$example"
    run_test "${example}_Infrastructure_Destruction" "${TESTS_DIR}/destroy-infrastructure.sh" "$example"

    log "SUCCESS" "=== Completed tests for example: $example ==="
    export EXAMPLE_NAME="$original_example"
    return 0
}

# Main execution function
main() {
    # Set up cleanup trap
    trap cleanup EXIT

    # Initialize
    export TEST_START_TIME=$(date +%s)
    init_logging

    # Parse arguments
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    # Validate arguments
    if [[ "$example_name" == "all" ]]; then
        log "INFO" "Running tests for all examples"

        # Initialize temporary results file
        > "${TEST_RESULTS_DIR}/temp_results.xml"

        local overall_success=true

        for example in "${ALL_EXAMPLES[@]}"; do
            if ! run_example_tests "$example"; then
                overall_success=false
                log "ERROR" "Tests failed for example: $example"
            fi
        done

        # Generate final report
        export TEST_END_TIME=$(date +%s)
        export TESTS_TOTAL TESTS_PASSED TESTS_FAILED
        "${UTILS_DIR}/generate-report.sh" "all"

        if [[ "$overall_success" == "true" && $TESTS_FAILED -eq 0 ]]; then
            log "SUCCESS" "All tests passed for all examples!"
            exit 0
        else
            log "ERROR" "Some tests failed!"
            exit 1
        fi

    elif [[ ! "$example_name" =~ ^(minimal|existing-infrastructure)$ ]]; then
        log "ERROR" "Invalid example name: $example_name. Must be 'minimal', 'existing-infrastructure', or 'all'"
        exit 1
    else
        # Initialize temporary results file
        > "${TEST_RESULTS_DIR}/temp_results.xml"

        # Execute test suite for single example
        if run_example_tests "$example_name"; then
            export TEST_END_TIME=$(date +%s)
            export TESTS_TOTAL TESTS_PASSED TESTS_FAILED
            "${UTILS_DIR}/generate-report.sh" "$example_name"

            if [[ $TESTS_FAILED -eq 0 ]]; then
                log "SUCCESS" "All tests passed!"
                exit 0
            else
                log "ERROR" "$TESTS_FAILED tests failed!"
                exit 1
            fi
        else
            export TEST_END_TIME=$(date +%s)
            export TESTS_TOTAL TESTS_PASSED TESTS_FAILED
            "${UTILS_DIR}/generate-report.sh" "$example_name"
            log "ERROR" "Tests failed for example: $example_name"
            exit 1
        fi
    fi
}

# Usage information
usage() {
    cat << EOF
Usage: $0 [EXAMPLE_NAME]

Haven AKS Terraform Module Integration Test Orchestrator

Arguments:
  EXAMPLE_NAME    Name of the example to test:
                  - minimal: Test minimal example
                  - existing-infrastructure: Test existing-infrastructure example
                  - all: Test all examples sequentially
                  Default: minimal

Environment Variables:
  SKIP_DESTROY    Skip infrastructure destruction (true|false) [default: false]
  DRY_RUN         Perform dry run without actual execution (true|false) [default: false]
  CI_MODE         Enable CI mode (disables colors, etc.) (true|false) [default: false]

Examples:
  $0 minimal                          # Test minimal example
  $0 existing-infrastructure          # Test existing-infrastructure example
  $0 all                              # Test all examples
  SKIP_DESTROY=true $0 minimal        # Test without destroying resources
  DRY_RUN=true $0 minimal             # Dry run test
  CI_MODE=true $0 all                 # CI mode with all examples

Output:
  - JUnit XML report: test-results/integration-test-report.xml
  - Detailed log: test-results/integration-test.log
  - Summary: test-results/summary.txt

Exit Codes:
  0    All tests passed
  1    One or more tests failed
  2    Invalid arguments or prerequisites not met

Architecture:
  - Orchestrator: integration-test-orchestrator.sh (this script)
  - Common Library: lib/common.sh
  - Test Scripts: tests/*.sh (each handles one responsibility)
  - Utilities: utils/*.sh (report generation, etc.)

Features:
  - Modular design following single responsibility principle
  - Supports both local and CI/CD execution
  - GitLab CI compatible JUnit XML reporting
  - Dry run mode for testing the test suite
  - Skip destroy for debugging failed deployments
  - Comprehensive logging and error reporting
  - Automatic cleanup of temporary files
  - Support for testing all examples in sequence

EOF
}

# Handle help flag
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    usage
    exit 0
fi

# Execute main function
main "$@"
