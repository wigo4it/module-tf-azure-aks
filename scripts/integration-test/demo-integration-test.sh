#!/bin/bash

# Demonstration script for Haven AKS Integration Test Suite
# This script shows various ways to use the integration test

set -euo pipefail

echo "=== Haven AKS Integration Test Demonstration ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

demo_section() {
    echo -e "${BLUE}=== $1 ===${NC}"
    echo ""
}

demo_command() {
    echo -e "${GREEN}$ $1${NC}"
    echo ""
}

demo_section "1. Basic Usage"
demo_command "# Test the minimal example"
demo_command "./integration-test.sh minimal"
echo ""

demo_command "# Test the existing-infrastructure example"
demo_command "./integration-test.sh existing-infrastructure"
echo ""

demo_command "# Test all examples"
demo_command "./integration-test.sh all"
echo ""

demo_section "2. Advanced Options"
demo_command "# Dry run - show what would be done without executing"
demo_command "DRY_RUN=true ./integration-test.sh all"
echo ""

demo_command "# Skip destruction - useful for debugging failed deployments"
demo_command "SKIP_DESTROY=true ./integration-test.sh minimal"
echo ""

demo_command "# CI mode - disable colors and interactive features"
demo_command "CI_MODE=true ./integration-test.sh all"
echo ""

demo_section "3. Common Use Cases"
demo_command "# Quick validation of terraform configuration"
demo_command "DRY_RUN=true ./integration-test.sh minimal"
echo ""

demo_command "# Full integration test in CI/CD pipeline"
demo_command "CI_MODE=true ./integration-test.sh all"
echo ""

demo_command "# Debug a failed deployment"
demo_command "SKIP_DESTROY=true ./integration-test.sh existing-infrastructure"
echo ""

demo_section "4. Output Files"
echo "After running the integration tests, you'll find:"
echo "- test-results/integration-test-report.xml (JUnit XML for CI/CD)"
echo "- test-results/integration-test.log (Detailed execution log)"
echo "- test-results/summary.txt (Human-readable summary)"
echo ""

demo_section "5. Prerequisites"
echo "Before running integration tests, ensure you have:"
echo "- Azure CLI installed and authenticated (az login)"
echo "- Terraform installed (version 1.5+)"
echo "- kubectl installed"
echo "- jq installed"
echo "- Appropriate Azure permissions (Contributor role recommended)"
echo ""

demo_section "6. Help"
demo_command "./integration-test.sh --help"
echo ""

echo "=== Ready to run integration tests! ==="
echo ""
echo "Start with a dry run to validate your setup:"
echo -e "${GREEN}DRY_RUN=true ./integration-test.sh minimal${NC}"
echo ""
