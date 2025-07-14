#!/bin/bash

# Haven AKS Integration Test - AKS Connectivity Test
# Tests basic AKS cluster connectivity and node status

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Test AKS connectivity
test_aks_connectivity() {
    log "INFO" "Testing AKS connectivity..."

    # Test cluster info
    if ! kubectl cluster-info --request-timeout=30s > /dev/null; then
        log "ERROR" "Could not connect to AKS cluster"
        return 1
    fi

    # Test node status
    local node_count
    node_count=$(kubectl get nodes --no-headers | wc -l)

    if [[ "$node_count" -lt 1 ]]; then
        log "ERROR" "No nodes found in cluster"
        return 1
    fi

    # Test node readiness
    local ready_nodes
    ready_nodes=$(kubectl get nodes --no-headers | grep -c "Ready" || true)

    if [[ "$ready_nodes" -lt 1 ]]; then
        log "ERROR" "No ready nodes found"
        return 1
    fi

    log "SUCCESS" "AKS connectivity test passed"
    log "INFO" "Nodes: $node_count ready, $ready_nodes total"
    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    test_aks_connectivity
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
