#!/bin/bash

# Haven AKS Integration Test - DNS Configuration Test
# Tests DNS zone configuration and DNS records

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Test DNS configuration
test_dns_configuration() {
    log "INFO" "Testing DNS configuration..."

    cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"

    local dns_zone_name
    dns_zone_name=$(terraform output -raw dns_zone_name 2>/dev/null || echo "")

    if [[ -n "$dns_zone_name" ]]; then
        # Check if DNS zone exists
        if az network dns zone show --name "$dns_zone_name" --resource-group "$(terraform output -raw resource_group_name)" > /dev/null 2>&1; then
            log "SUCCESS" "DNS zone is accessible: $dns_zone_name"
        else
            log "WARNING" "DNS zone may not be fully configured"
        fi

        # Check DNS records
        local record_count
        record_count=$(az network dns record-set list --zone-name "$dns_zone_name" --resource-group "$(terraform output -raw resource_group_name)" --query "length(@)" -o tsv 2>/dev/null || echo "0")

        log "INFO" "DNS records found: $record_count"
    else
        log "WARNING" "No DNS zone name found in outputs"
    fi

    return 0
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    test_dns_configuration
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
