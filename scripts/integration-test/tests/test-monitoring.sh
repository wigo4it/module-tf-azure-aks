#!/bin/bash

# Haven AKS Integration Test - Monitoring Integration Test
# Tests monitoring components like Log Analytics and Container Insights

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Test monitoring integration
test_monitoring() {
    log "INFO" "Testing monitoring integration..."

    # Check if Log Analytics workspace is accessible
    cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"

    local workspace_id
    workspace_id=$(terraform output -raw log_analytics_workspace_id 2>/dev/null || echo "")

    if [[ -n "$workspace_id" ]]; then
        # Verify workspace exists and is accessible
        if az monitor log-analytics workspace show --ids "$workspace_id" > /dev/null 2>&1; then
            log "SUCCESS" "Log Analytics workspace is accessible"
        else
            log "WARNING" "Log Analytics workspace exists but may not be fully accessible"
        fi
    else
        log "WARNING" "No Log Analytics workspace ID found in outputs"
    fi

    # Check if Container Insights is enabled
    if kubectl get pods -n kube-system | grep -q "oms-agent"; then
        log "SUCCESS" "Container Insights (OMS agent) is running"
    else
        log "WARNING" "Container Insights (OMS agent) not found"
    fi

    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    test_monitoring
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
