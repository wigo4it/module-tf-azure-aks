#!/bin/bash

# Haven AKS Integration Test - Setup Test Infrastructure
# Sets up test infrastructure for existing-infrastructure example

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Test existing-infrastructure example setup
setup_test_infrastructure() {
    if [[ "$EXAMPLE_NAME" == "existing-infrastructure" ]]; then
        log "INFO" "Setting up test infrastructure for existing-infrastructure example..."

        cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"

        # Load environment variables from .env file if it exists
        if [[ -f ".env" ]]; then
            log "INFO" "Loading environment variables from .env file"
            set -a  # automatically export all variables
            source .env
            set +a  # stop automatically exporting
        fi

        # Check if setup file exists
        if [[ -f "setup-test-infrastructure.tf" ]]; then
            # First initialize if needed
            if ! terraform init -input=false > /dev/null 2>&1; then
                log "ERROR" "Failed to initialize terraform for setup"
                return 1
            fi

            # Apply the setup resources only (target specific resources)
            log "INFO" "Applying setup infrastructure resources..."
            if ! terraform apply -auto-approve \
                -target=azurerm_resource_group.networking \
                -target=azurerm_virtual_network.networking \
                -target=azurerm_subnet.networking \
                -target=azurerm_resource_group.dns \
                -target=azurerm_dns_zone.dns \
                -target=azurerm_resource_group.monitoring \
                -target=azurerm_log_analytics_workspace.monitoring > /dev/null 2>&1; then
                log "ERROR" "Failed to setup test infrastructure"
                return 1
            fi

            # Get the Log Analytics workspace ID and update terraform.tfvars
            local workspace_id
            workspace_id=$(terraform output -raw test_log_analytics_workspace_id 2>/dev/null || echo "")

            if [[ -n "$workspace_id" ]]; then
                # Update terraform.tfvars with the workspace ID using a different delimiter to avoid issues with forward slashes
                if grep -q "existing_log_analytics_workspace_id" terraform.tfvars; then
                    # Use @ as delimiter instead of / to avoid conflicts with the workspace ID path
                    sed -i "s@existing_log_analytics_workspace_id = null@existing_log_analytics_workspace_id = \"$workspace_id\"@" terraform.tfvars
                else
                    echo "existing_log_analytics_workspace_id = \"$workspace_id\"" >> terraform.tfvars
                fi

                log "SUCCESS" "Test infrastructure setup completed with workspace ID: $workspace_id"
            else
                log "WARNING" "Could not retrieve workspace ID from setup"
            fi
        else
            log "INFO" "No setup-test-infrastructure.tf found, skipping setup"
        fi
    fi

    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    setup_test_infrastructure
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
