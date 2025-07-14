#!/bin/bash

# Haven AKS Integration Test - Terraform Validation
# Validates Terraform configuration, formatting, and initialization

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Validate Terraform configuration
validate_terraform() {
    log "INFO" "Validating Terraform configuration..."

    cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"

    # Load environment variables from .env file if it exists and we're in the right example
    if [[ "$EXAMPLE_NAME" == "existing-infrastructure" && -f ".env" ]]; then
        log "INFO" "Loading environment variables from .env file"
        set -a  # automatically export all variables
        source .env
        set +a  # stop automatically exporting
    fi

    # Initialize Terraform
    if ! terraform init -input=false; then
        log "ERROR" "Terraform init failed"
        return 1
    fi

    # Validate configuration
    if ! terraform validate; then
        log "ERROR" "Terraform validation failed"
        return 1
    fi

    # Check formatting
    if ! terraform fmt -check; then
        log "ERROR" "Terraform files are not properly formatted"
        return 1
    fi

    log "SUCCESS" "Terraform configuration is valid"
    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    validate_terraform
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
