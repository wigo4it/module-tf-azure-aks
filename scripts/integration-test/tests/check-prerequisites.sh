#!/bin/bash

# Haven AKS Integration Test - Prerequisites Check
# Validates required tools and authentication

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Check prerequisites
check_prerequisites() {
    log "INFO" "Checking prerequisites..."

    # Load environment variables from .env file if it exists and we're in the right example
    if [[ "$EXAMPLE_NAME" == "existing-infrastructure" && -f "${EXAMPLES_DIR}/${EXAMPLE_NAME}/.env" ]]; then
        log "INFO" "Loading environment variables from .env file"
        set -a  # automatically export all variables
        source "${EXAMPLES_DIR}/${EXAMPLE_NAME}/.env"
        set +a  # stop automatically exporting
    fi

    # Check required tools
    local required_tools=("terraform" "kubectl" "az" "jq")
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log "ERROR" "Required tool not found: $tool"
            return 1
        fi
    done

    # Check Azure authentication
    if ! az account show &> /dev/null; then
        log "ERROR" "Not authenticated with Azure CLI"
        return 1
    fi

    # Check if example directory exists
    if [[ ! -d "${EXAMPLES_DIR}/${EXAMPLE_NAME}" ]]; then
        log "ERROR" "Example directory not found: ${EXAMPLES_DIR}/${EXAMPLE_NAME}"
        return 1
    fi

    log "SUCCESS" "Prerequisites check passed"
    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    check_prerequisites
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
