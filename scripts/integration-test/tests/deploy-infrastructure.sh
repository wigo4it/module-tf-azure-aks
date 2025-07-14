#!/bin/bash

# Haven AKS Integration Test - Infrastructure Deployment
# Deploys infrastructure using Terraform

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Deploy infrastructure
deploy_infrastructure() {
    log "INFO" "Deploying infrastructure..."

    cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"

    # Load environment variables from .env file if it exists and we're in the right example
    if [[ "$EXAMPLE_NAME" == "existing-infrastructure" && -f ".env" ]]; then
        log "INFO" "Loading environment variables from .env file"
        set -a  # automatically export all variables
        source .env
        set +a  # stop automatically exporting
    fi

    # Apply Terraform
    if ! terraform apply -input=false -auto-approve tfplan; then
        log "ERROR" "Terraform apply failed"
        return 1
    fi

    # Get outputs
    local cluster_name
    cluster_name=$(terraform output -raw cluster_name 2>/dev/null || echo "")

    if [[ -z "$cluster_name" ]]; then
        log "ERROR" "Could not retrieve cluster name from Terraform outputs"
        return 1
    fi

    log "SUCCESS" "Infrastructure deployed successfully"
    log "INFO" "Cluster: $cluster_name"
    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    deploy_infrastructure
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
