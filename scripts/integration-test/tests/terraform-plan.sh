#!/bin/bash

# Haven AKS Integration Test - Terraform Plan
# Executes Terraform plan and validates planned resources

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Execute Terraform plan
execute_terraform_plan() {
    log "INFO" "Executing Terraform plan..."

    cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"

    # Load environment variables from .env file if it exists and we're in the right example
    if [[ "$EXAMPLE_NAME" == "existing-infrastructure" && -f ".env" ]]; then
        log "INFO" "Loading environment variables from .env file"
        set -a  # automatically export all variables
        source .env
        set +a  # stop automatically exporting
    fi

    # Create plan
    if ! terraform plan -input=false -out=tfplan; then
        log "ERROR" "Terraform plan failed"
        return 1
    fi

    # Verify plan contains expected resources
    local plan_json
    plan_json=$(terraform show -json tfplan)

    local resource_count
    resource_count=$(echo "$plan_json" | jq -r '.planned_values.root_module.resources | length')

    if [[ "$resource_count" -lt 5 ]]; then
        log "ERROR" "Plan contains insufficient resources: $resource_count"
        return 1
    fi

    log "SUCCESS" "Terraform plan successful with $resource_count resources"
    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    execute_terraform_plan
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
