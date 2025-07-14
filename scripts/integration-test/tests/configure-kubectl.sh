#!/bin/bash

# Haven AKS Integration Test - Kubectl Configuration
# Configures kubectl for AKS cluster access

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Configure kubectl
configure_kubectl() {
    log "INFO" "Configuring kubectl..."

    cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"

    # Load environment variables from .env file if it exists
    if [[ -f ".env" ]]; then
        log "INFO" "Loading environment variables from .env file"
        set -a  # automatically export all variables
        source .env
        set +a  # stop automatically exporting
    fi

    # Set the correct subscription context
    if [[ -n "${ARM_SUBSCRIPTION_ID:-}" ]]; then
        log "INFO" "Setting subscription context to: $ARM_SUBSCRIPTION_ID"
        az account set --subscription "$ARM_SUBSCRIPTION_ID"
    fi

    # Get cluster credentials
    local cluster_name resource_group
    cluster_name=$(terraform output -raw cluster_name 2>/dev/null || echo "")
    resource_group=$(terraform output -raw resource_group_name 2>/dev/null || echo "")

    if [[ -z "$cluster_name" || -z "$resource_group" ]]; then
        log "ERROR" "Could not retrieve cluster information from outputs"
        return 1
    fi

    # Get AKS credentials
    if ! az aks get-credentials --resource-group "$resource_group" --name "$cluster_name" --overwrite-existing; then
        log "ERROR" "Failed to get AKS credentials"
        return 1
    fi

    log "SUCCESS" "kubectl configured successfully"
    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    configure_kubectl
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
