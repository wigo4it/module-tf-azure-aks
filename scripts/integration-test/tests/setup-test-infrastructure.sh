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
            # Clean up any existing Azure resources from previous test runs
            log "INFO" "Cleaning up existing test resources if any..."
            local resource_groups=(
                "rg-560x-haven-test"
                "rg-haven-aks-test"
                "rg-haven-networking-test"
                "rg-haven-dns-test"
                "rg-haven-monitoring-test"
                "rg-haven-acr-test"
                "rg-haven-security-test"
                "rg-haven-monitoring-alerts-test"
                "rg-haven-alerts-test"
            )
            
            local groups_to_delete=()
            for rg in "${resource_groups[@]}"; do
                if az group show --name "$rg" &>/dev/null; then
                    log "INFO" "Found existing resource group: $rg"
                    groups_to_delete+=("$rg")
                fi
            done
            
            if [ ${#groups_to_delete[@]} -gt 0 ]; then
                log "INFO" "Deleting ${#groups_to_delete[@]} resource group(s)..."
                for rg in "${groups_to_delete[@]}"; do
                    az group delete --name "$rg" --yes --no-wait
                done
                
                # Wait for all deletions to complete
                log "INFO" "Waiting for resource group deletions to complete (this may take several minutes)..."
                for rg in "${groups_to_delete[@]}"; do
                    while az group show --name "$rg" &>/dev/null; do
                        sleep 10
                    done
                    log "INFO" "Resource group deleted: $rg"
                done
                log "SUCCESS" "All existing resource groups cleaned up"
            fi

            # Remove any existing state to start fresh (handles resource structure changes)
            if [[ -f "terraform.tfstate" ]]; then
                log "INFO" "Removing existing terraform state for clean deployment..."
                rm -f terraform.tfstate terraform.tfstate.backup
            fi

            # First initialize if needed
            if ! terraform init -input=false; then
                log "ERROR" "Failed to initialize terraform for setup"
                return 1
            fi

            # Apply the setup resources only (target specific resources)
            log "INFO" "Applying setup infrastructure resources..."
            if ! terraform apply -auto-approve \
                -target=azurerm_resource_group.aks \
                -target=azurerm_resource_group.networking \
                -target=azurerm_virtual_network.networking \
                -target=azurerm_subnet.networking \
                -target=azurerm_private_dns_zone.aks \
                -target=azurerm_private_dns_zone_virtual_network_link.aks \
                -target=azurerm_resource_group.dns \
                -target=azurerm_dns_zone.dns \
                -target=azurerm_resource_group.monitoring \
                -target=azurerm_log_analytics_workspace.monitoring \
                -target=azurerm_resource_group.acr \
                -target=azurerm_container_registry.acr \
                -target=azurerm_resource_group.security \
                -target=azurerm_key_vault.security \
                -target=azurerm_key_vault_access_policy.current_user \
                -target=azurerm_key_vault_key.disk_encryption \
                -target=azurerm_disk_encryption_set.aks \
                -target=azurerm_key_vault_access_policy.disk_encryption_set \
                -target=azurerm_resource_group.monitoring_alerts \
                -target=azurerm_monitor_action_group.aks_alerts; then
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
                    sed -i "s@existing_log_analytics_workspace_id = \"REPLACE_WITH_LOG_ANALYTICS_WORKSPACE_ID\"@existing_log_analytics_workspace_id = \"$workspace_id\"@" terraform.tfvars
                else
                    echo "existing_log_analytics_workspace_id = \"$workspace_id\"" >> terraform.tfvars
                fi

                log "SUCCESS" "Test infrastructure setup completed with workspace ID: $workspace_id"
            else
                log "WARNING" "Could not retrieve workspace ID from setup"
            fi

            # Get the ACR ID and update terraform.tfvars
            local acr_id
            acr_id=$(terraform output -raw test_acr_id 2>/dev/null || echo "")

            if [[ -n "$acr_id" ]]; then
                # Update terraform.tfvars with the ACR ID
                if grep -q "container_registry_id" terraform.tfvars; then
                    # Use @ as delimiter instead of / to avoid conflicts with the ACR ID path
                    sed -i "s@container_registry_id = null@container_registry_id = \"$acr_id\"@" terraform.tfvars
                    sed -i "s@container_registry_id = \"REPLACE_WITH_ACR_ID\"@container_registry_id = \"$acr_id\"@" terraform.tfvars
                    sed -i "s@container_registry_id               = null@container_registry_id = \"$acr_id\"@" terraform.tfvars
                    sed -i "s@container_registry_id               = \"REPLACE_WITH_ACR_ID\"@container_registry_id = \"$acr_id\"@" terraform.tfvars
                else
                    echo "container_registry_id = \"$acr_id\"" >> terraform.tfvars
                fi

                log "SUCCESS" "ACR integration configured with ID: $acr_id"
            else
                log "WARNING" "Could not retrieve ACR ID from setup"
            fi

            # Get the Disk Encryption Set ID and update terraform.tfvars
            local des_id
            des_id=$(terraform output -raw test_disk_encryption_set_id 2>/dev/null || echo "")

            if [[ -n "$des_id" ]]; then
                # Update terraform.tfvars with the DES ID
                if grep -q "disk_encryption_set_id" terraform.tfvars; then
                    sed -i "s@disk_encryption_set_id = null@disk_encryption_set_id = \"$des_id\"@" terraform.tfvars
                    sed -i "s@disk_encryption_set_id = \"REPLACE_WITH_DES_ID\"@disk_encryption_set_id = \"$des_id\"@" terraform.tfvars
                    sed -i "s@disk_encryption_set_id              = null@disk_encryption_set_id = \"$des_id\"@" terraform.tfvars
                    sed -i "s@disk_encryption_set_id              = \"REPLACE_WITH_DES_ID\"@disk_encryption_set_id = \"$des_id\"@" terraform.tfvars
                else
                    echo "disk_encryption_set_id = \"$des_id\"" >> terraform.tfvars
                fi

                log "SUCCESS" "CMK disk encryption configured with DES ID: $des_id"
            else
                log "WARNING" "Could not retrieve Disk Encryption Set ID from setup"
            fi

            # Get the Action Group ID and update terraform.tfvars
            local action_group_id
            action_group_id=$(terraform output -raw test_action_group_id 2>/dev/null || echo "")

            if [[ -n "$action_group_id" ]]; then
                # Update terraform.tfvars with the Action Group ID
                if grep -q "monitoring_action_group_id" terraform.tfvars; then
                    sed -i "s@monitoring_action_group_id = null@monitoring_action_group_id = \"$action_group_id\"@" terraform.tfvars
                    sed -i "s@monitoring_action_group_id = \"REPLACE_WITH_ACTION_GROUP_ID\"@monitoring_action_group_id = \"$action_group_id\"@" terraform.tfvars
                    sed -i "s@monitoring_action_group_id          = null@monitoring_action_group_id = \"$action_group_id\"@" terraform.tfvars
                    sed -i "s@monitoring_action_group_id          = \"REPLACE_WITH_ACTION_GROUP_ID\"@monitoring_action_group_id = \"$action_group_id\"@" terraform.tfvars
                else
                    echo "monitoring_action_group_id = \"$action_group_id\"" >> terraform.tfvars
                fi

                log "SUCCESS" "Monitoring alerts configured with Action Group ID: $action_group_id"
            else
                log "WARNING" "Could not retrieve Action Group ID from setup"
            fi

            # Get the Private DNS Zone ID and update terraform.tfvars
            local private_dns_zone_id
            private_dns_zone_id=$(terraform output -raw test_private_dns_zone_id 2>/dev/null || echo "")

            if [[ -n "$private_dns_zone_id" ]]; then
                # Update terraform.tfvars with the Private DNS Zone ID
                if grep -q "private_dns_zone_id" terraform.tfvars; then
                    sed -i "s@private_dns_zone_id = null@private_dns_zone_id = \"$private_dns_zone_id\"@" terraform.tfvars
                    sed -i "s@private_dns_zone_id = \"REPLACE_WITH_PRIVATE_DNS_ZONE_ID\"@private_dns_zone_id = \"$private_dns_zone_id\"@" terraform.tfvars
                    sed -i "s@private_dns_zone_id                 = null@private_dns_zone_id = \"$private_dns_zone_id\"@" terraform.tfvars
                    sed -i "s@private_dns_zone_id                 = \"REPLACE_WITH_PRIVATE_DNS_ZONE_ID\"@private_dns_zone_id = \"$private_dns_zone_id\"@" terraform.tfvars
                else
                    echo "private_dns_zone_id = \"$private_dns_zone_id\"" >> terraform.tfvars
                fi

                log "SUCCESS" "Private DNS zone configured with ID: $private_dns_zone_id"
            else
                log "WARNING" "Could not retrieve Private DNS Zone ID from setup"
            fi

            # Format terraform.tfvars after all modifications
            if command -v terraform &>/dev/null; then
                terraform fmt terraform.tfvars &>/dev/null
                log "INFO" "Formatted terraform.tfvars after configuration updates"
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
