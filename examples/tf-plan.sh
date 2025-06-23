#!/usr/bin/env bash
# Example script: Run Terraform init, plan, and apply for the minimal example
# Usage: ./run-terraform.sh [testcase]
# Example: ./run-terraform.sh minimal

set -euo pipefail

# Set testcase directory (default: minimal)
TESTCASE=${1:-minimal}
EXAMPLE_DIR="$(dirname "$0")/$TESTCASE"

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
