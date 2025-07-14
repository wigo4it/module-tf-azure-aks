#!/bin/bash

# Haven AKS Integration Test - Kubernetes Operations Test
# Tests basic Kubernetes operations like namespace, pod, and service creation

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Test basic Kubernetes operations
test_kubernetes_operations() {
    log "INFO" "Testing basic Kubernetes operations..."

    # Test namespace creation
    local test_namespace="integration-test-$(date +%s)"

    if ! kubectl create namespace "$test_namespace"; then
        log "ERROR" "Failed to create test namespace"
        return 1
    fi

    # Test pod creation
    if ! kubectl run test-pod --image=nginx:alpine --restart=Never -n "$test_namespace" --timeout=60s; then
        log "ERROR" "Failed to create test pod"
        kubectl delete namespace "$test_namespace" --ignore-not-found=true
        return 1
    fi

    # Wait for pod to be ready
    if ! kubectl wait --for=condition=Ready pod/test-pod -n "$test_namespace" --timeout=120s; then
        log "ERROR" "Test pod did not become ready"
        kubectl delete namespace "$test_namespace" --ignore-not-found=true
        return 1
    fi

    # Test service creation
    if ! kubectl expose pod test-pod --port=80 --target-port=80 -n "$test_namespace"; then
        log "ERROR" "Failed to create test service"
        kubectl delete namespace "$test_namespace" --ignore-not-found=true
        return 1
    fi

    # Cleanup test resources
    kubectl delete namespace "$test_namespace" --ignore-not-found=true

    log "SUCCESS" "Kubernetes operations test passed"
    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    test_kubernetes_operations
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
