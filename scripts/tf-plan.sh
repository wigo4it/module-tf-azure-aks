#!/usr/bin/env bash
# Example script: Run Terraform init, plan, and apply for Haven module examples
# Usage: ./tf-plan.sh [testcase]
# Examples:
#   ./tf-plan.sh minimal
#   ./tf-plan.sh existing-infrastructure

set -euo pipefail

# Set testcase directory (default: minimal)
TESTCASE=${1:-minimal}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
EXAMPLE_DIR="$PROJECT_ROOT/examples/$TESTCASE"

if [ ! -d "$EXAMPLE_DIR" ]; then
  echo "Error: Example directory '$EXAMPLE_DIR' does not exist." >&2
  exit 1
fi

# Load environment variables from .env if present
if [ -f "$EXAMPLE_DIR/.env" ]; then
  echo "Loading environment variables from $EXAMPLE_DIR/.env"
  set -a
  # shellcheck disable=SC1090
  source "$EXAMPLE_DIR/.env"
  set +a
fi

cd "$EXAMPLE_DIR"

echo "Initializing Terraform in $EXAMPLE_DIR..."
terraform init

echo "Running Terraform plan..."
terraform plan -out=tfplan

echo "Applying Terraform plan..."
# Uncomment the next line to actually apply the plan
# terraform apply tfplan

echo "Done."
