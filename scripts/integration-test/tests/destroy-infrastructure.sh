#!/bin/bash

# Haven AKS Integration Test - Infrastructure Destruction
# Destroys infrastructure using Terraform with retry logic

set -euo pipefail

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Destroy infrastructure
destroy_infrastructure() {
    if [[ "$SKIP_DESTROY" == "true" ]]; then
        log "INFO" "Skipping infrastructure destruction (SKIP_DESTROY=true)"
        return 0
    fi

    log "INFO" "Destroying infrastructure..."

    cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"

    # Load environment variables from .env file if it exists and we're in the right example
    if [[ "$EXAMPLE_NAME" == "existing-infrastructure" && -f ".env" ]]; then
        log "INFO" "Loading environment variables from .env file"
        set -a  # automatically export all variables
        source .env
        set +a  # stop automatically exporting
    fi

    # Destroy with retry logic
    local max_attempts=3
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        log "INFO" "Destruction attempt $attempt/$max_attempts"

        if terraform destroy -input=false -auto-approve; then
            log "SUCCESS" "Infrastructure destroyed successfully"
            return 0
        else
            log "WARNING" "Destruction attempt $attempt failed"

            if [[ $attempt -lt $max_attempts ]]; then
                log "INFO" "Waiting 30 seconds before retry..."
                sleep 30
            fi
        fi

        attempt=$((attempt + 1))
    done

    log "ERROR" "Failed to destroy infrastructure after $max_attempts attempts"
    return 1
}

# Main execution
main() {
    local example_name="${1:-minimal}"
    export EXAMPLE_NAME="$example_name"

    destroy_infrastructure
}

# Execute if run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
