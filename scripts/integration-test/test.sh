#!/bin/bash
# Haven AKS — Integration Test
# Single-file orchestrator. Each test step is a function; common.sh holds shared helpers.
# Usage: ./test.sh [minimal|existing-infrastructure|all]  (default: minimal)
# Env:   SKIP_DESTROY=true  DRY_RUN=true  CI_MODE=true

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"

# ---------------------------------------------------------------------------
# Step 1 — Prerequisites
# ---------------------------------------------------------------------------
check_prerequisites() {
  log "INFO" "Checking prerequisites..."
  load_env "${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  local required_tools=("terraform" "kubectl" "az" "jq")
  for tool in "${required_tools[@]}"; do
    command -v "$tool" >/dev/null 2>&1 || { log "ERROR" "Missing tool: $tool"; return 1; }
  done
  az account show >/dev/null 2>&1 || { log "ERROR" "Not authenticated with Azure CLI"; return 1; }
  [[ -d "${EXAMPLES_DIR}/${EXAMPLE_NAME}" ]] || { log "ERROR" "Example not found: ${EXAMPLES_DIR}/${EXAMPLE_NAME}"; return 1; }
  log "SUCCESS" "Prerequisites OK"
}

# ---------------------------------------------------------------------------
# Step 2 — Terraform init + validate + fmt check
# ---------------------------------------------------------------------------
validate_terraform() {
  log "INFO" "Validating Terraform..."
  cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  load_env .
  terraform init -input=false
  terraform validate
  terraform fmt -check || log "WARNING" "Formatting issues found"
  log "SUCCESS" "Terraform validation OK"
}

# ---------------------------------------------------------------------------
# Step 3 — Terraform plan
# ---------------------------------------------------------------------------
terraform_plan() {
  log "INFO" "Running terraform plan..."
  cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  load_env .
  terraform plan -input=false -out=tfplan
  log "SUCCESS" "Terraform plan OK"
}

# ---------------------------------------------------------------------------
# Helper — update a key=value pair in terraform.tfvars (used by step 4)
# ---------------------------------------------------------------------------
_patch_tfvars() {
  local key="$1" value="$2"
  [[ -z "$value" ]] && return
  if grep -q "$key" terraform.tfvars; then
    sed -i "s@${key}[[:space:]]*=[[:space:]]*.*@${key} = \"$value\"@" terraform.tfvars
  else
    echo "${key} = \"$value\"" >> terraform.tfvars
  fi
}

# ---------------------------------------------------------------------------
# Step 4 (existing-infrastructure only) — Setup prerequisite Azure resources
# ---------------------------------------------------------------------------
setup_existing_infra() {
  [[ "$EXAMPLE_NAME" == "existing-infrastructure" ]] || return 0
  local dir="${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  [[ -f "$dir/setup-test-infrastructure.tf" ]] || { log "INFO" "No setup file, skipping"; return 0; }

  log "INFO" "Setting up existing-infrastructure prerequisites..."
  cd "$dir"
  load_env .

  # Clean up any leftover state from a previous run
  terraform init -input=false -upgrade=false >/dev/null 2>&1 || terraform init -input=false
  if [[ -f terraform.tfstate ]] && \
     [[ "$(terraform show -json terraform.tfstate 2>/dev/null \
          | jq -r '.values.root_module.resources | length' 2>/dev/null || echo 0)" -gt 0 ]]; then

    # Delete the AKS resource group first to release OS-disk locks on the DES
    local aks_rg
    aks_rg=$(terraform show -json terraform.tfstate 2>/dev/null \
      | jq -r '.values.root_module.child_modules[]?.resources[]?
               | select(.type=="azurerm_kubernetes_cluster")
               | .values.resource_group_name' 2>/dev/null | head -1 || echo "")
    if [[ -n "$aks_rg" ]] && az group show --name "$aks_rg" >/dev/null 2>&1; then
      log "INFO" "Deleting AKS RG $aks_rg to release OS-disk locks..."
      az group delete --name "$aks_rg" --yes
    fi

    terraform destroy -auto-approve -input=false -refresh=false \
      || log "WARNING" "Destroy had errors; continuing with fallback cleanup"

    # Fallback: delete any surviving test resource groups
    local fallback_rgs=(
      "rg-560x-haven-test" "rg-haven-networking-test" "rg-haven-dns-test"
      "rg-haven-monitoring-test" "rg-haven-acr-test" "rg-haven-security-test"
      "rg-haven-alerts-test"
    )
    for rg in "${fallback_rgs[@]}"; do
      az group show --name "$rg" >/dev/null 2>&1 \
        && az group delete --name "$rg" --yes --no-wait || true
    done
    for rg in "${fallback_rgs[@]}"; do
      while az group show --name "$rg" >/dev/null 2>&1; do sleep 10; done
    done
    rm -f terraform.tfstate terraform.tfstate.backup
  fi

  terraform init -input=false
  terraform apply -auto-approve \
    -target=azurerm_resource_group.aks \
    -target=azurerm_resource_group.networking \
    -target=azurerm_virtual_network.networking \
    -target=azurerm_subnet.networking \
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
    -target=azurerm_monitor_action_group.aks_alerts

  # Patch each output back into terraform.tfvars (single helper, no repetition)
  _patch_tfvars "existing_log_analytics_workspace_id" \
    "$(terraform output -raw test_log_analytics_workspace_id 2>/dev/null || true)"

  _patch_tfvars "disk_encryption_set_id" \
    "$(terraform output -raw test_disk_encryption_set_id 2>/dev/null || true)"
  _patch_tfvars "monitoring_action_group_id" \
    "$(terraform output -raw test_action_group_id 2>/dev/null || true)"
  _patch_tfvars "private_dns_zone_id" \
    "$(terraform output -raw test_private_dns_zone_id 2>/dev/null || true)"

  terraform fmt terraform.tfvars >/dev/null 2>&1 || true
  log "SUCCESS" "Setup complete"
}

# ---------------------------------------------------------------------------
# Step 5 — Deploy
# ---------------------------------------------------------------------------
deploy_infrastructure() {
  log "INFO" "Deploying infrastructure..."
  cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  load_env .

  # Phase 1: cluster only (Defender may auto-create diagnostic settings during provisioning)
  terraform apply -input=false -auto-approve \
    -target=module.haven.azurerm_kubernetes_cluster.default \
    || { log "ERROR" "Phase 1 (cluster) failed"; return 1; }

  # Remove any diagnostic settings Azure auto-created before the full apply
  local cluster_id
  cluster_id=$(terraform show -json 2>/dev/null \
    | jq -r '.values.root_module.child_modules[]?.resources[]?
             | select(.type=="azurerm_kubernetes_cluster") | .values.id' \
    2>/dev/null | head -1 || true)
  if [[ -n "$cluster_id" ]]; then
    while IFS= read -r name; do
      [[ -z "$name" ]] && continue
      az monitor diagnostic-settings delete --name "$name" --resource "$cluster_id" \
        >/dev/null 2>&1 || true
    done < <(az monitor diagnostic-settings list \
               --resource "$cluster_id" --query "[].name" -o tsv 2>/dev/null || true)
  fi

  # Phase 2: full apply
  terraform apply -input=false -auto-approve \
    || { log "ERROR" "Phase 2 (full apply) failed"; return 1; }

  local cluster_name
  cluster_name=$(terraform output -raw cluster_name 2>/dev/null || true)
  [[ -n "$cluster_name" ]] || { log "ERROR" "No cluster_name in outputs"; return 1; }
  log "SUCCESS" "Deployed: $cluster_name"
}

# ---------------------------------------------------------------------------
# Step 6 — Configure kubectl
# ---------------------------------------------------------------------------
configure_kubectl() {
  log "INFO" "Configuring kubectl..."
  cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  load_env .
  [[ -n "${ARM_SUBSCRIPTION_ID:-}" ]] && az account set --subscription "$ARM_SUBSCRIPTION_ID"
  local cluster_name resource_group
  cluster_name=$(terraform output -raw cluster_name 2>/dev/null || true)
  resource_group=$(terraform output -raw resource_group_name 2>/dev/null || true)
  [[ -n "$cluster_name" && -n "$resource_group" ]] \
    || { log "ERROR" "Missing cluster outputs"; return 1; }
  az aks get-credentials \
    --resource-group "$resource_group" --name "$cluster_name" --overwrite-existing
  log "SUCCESS" "kubectl configured"
}

# ---------------------------------------------------------------------------
# Step 7 — AKS connectivity
# ---------------------------------------------------------------------------
test_aks_connectivity() {
  log "INFO" "Testing AKS connectivity..."
  kubectl cluster-info --request-timeout=30s >/dev/null \
    || { log "ERROR" "Cannot reach cluster API"; return 1; }
  local ready
  ready=$(kubectl get nodes --no-headers | grep -c "Ready" || true)
  [[ "$ready" -ge 1 ]] || { log "ERROR" "No ready nodes"; return 1; }
  log "SUCCESS" "$ready ready node(s)"
}

# ---------------------------------------------------------------------------
# Step 8 — Kubernetes operations
# ---------------------------------------------------------------------------
test_kubernetes_operations() {
  log "INFO" "Testing Kubernetes operations..."
  local ns="integration-test-$(date +%s)"
  kubectl create namespace "$ns"
  kubectl run test-pod --image=nginx:alpine --restart=Never -n "$ns" --timeout=60s
  kubectl wait --for=condition=Ready pod/test-pod -n "$ns" --timeout=120s
  kubectl expose pod test-pod --port=80 --target-port=80 -n "$ns"
  kubectl delete namespace "$ns" --ignore-not-found=true
  log "SUCCESS" "Kubernetes operations OK"
}

# ---------------------------------------------------------------------------
# Step 9 — Monitoring (non-fatal)
# ---------------------------------------------------------------------------
test_monitoring() {
  log "INFO" "Testing monitoring..."
  cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  local ws_id
  ws_id=$(terraform output -raw log_analytics_workspace_id 2>/dev/null || true)
  if [[ -n "$ws_id" ]]; then
    az monitor log-analytics workspace show --ids "$ws_id" >/dev/null 2>&1 \
      && log "SUCCESS" "Log Analytics workspace accessible" \
      || log "WARNING" "Log Analytics workspace not fully accessible"
  else
    log "WARNING" "No log_analytics_workspace_id output"
  fi
  kubectl get pods -n kube-system | grep -q "oms-agent" \
    && log "SUCCESS" "Container Insights agent running" \
    || log "WARNING" "Container Insights agent not found"
}

# ---------------------------------------------------------------------------
# Step 10 — DNS (non-fatal)
# ---------------------------------------------------------------------------
test_dns_configuration() {
  log "INFO" "Testing DNS configuration..."
  cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  local dns_zone rg
  dns_zone=$(terraform output -raw dns_zone_name 2>/dev/null || true)
  rg=$(terraform output -raw resource_group_name 2>/dev/null || true)
  if [[ -n "$dns_zone" ]]; then
    az network dns zone show --name "$dns_zone" --resource-group "$rg" >/dev/null 2>&1 \
      && log "SUCCESS" "DNS zone accessible: $dns_zone" \
      || log "WARNING" "DNS zone not fully accessible"
    local records
    records=$(az network dns record-set list \
      --zone-name "$dns_zone" --resource-group "$rg" --query "length(@)" -o tsv \
      2>/dev/null || echo 0)
    log "INFO" "DNS records: $records"
  else
    log "WARNING" "No dns_zone_name output"
  fi
}

# ---------------------------------------------------------------------------
# Step 11 — Destroy
# ---------------------------------------------------------------------------
destroy_infrastructure() {
  if [[ "$SKIP_DESTROY" == "true" ]]; then log "INFO" "SKIP_DESTROY=true"; return 0; fi
  log "INFO" "Destroying infrastructure..."
  cd "${EXAMPLES_DIR}/${EXAMPLE_NAME}"
  load_env .
  local attempt=1
  while [[ $attempt -le 3 ]]; do
    terraform destroy -input=false -auto-approve && { log "SUCCESS" "Destroyed"; return 0; }
    log "WARNING" "Attempt $attempt failed; retrying in 30s..."
    sleep 30
    attempt=$((attempt + 1))
  done
  log "ERROR" "Destroy failed after 3 attempts"
  return 1
}

# ---------------------------------------------------------------------------
# Orchestrate one example: run all steps in order
# ---------------------------------------------------------------------------
run_example() {
  local example="$1"
  export EXAMPLE_NAME="$example"
  [[ -d "${EXAMPLES_DIR}/${example}" ]] || { log "ERROR" "Unknown example: $example"; return 1; }
  log "INFO" "=== Starting: $example ==="

  # Setup only applies to existing-infrastructure
  [[ "$example" == "existing-infrastructure" ]] \
    && run_step "${example}_Setup" setup_existing_infra

  run_step "${example}_Prerequisites"      check_prerequisites
  run_step "${example}_TF_Validate"        validate_terraform
  run_step "${example}_TF_Plan"            terraform_plan
  run_step "${example}_Deploy"             deploy_infrastructure     || return 1
  run_step "${example}_Kubectl"            configure_kubectl         || return 1
  run_step "${example}_AKS_Connectivity"   test_aks_connectivity
  run_step "${example}_Kubernetes_Ops"     test_kubernetes_operations
  run_step "${example}_Monitoring"         test_monitoring           || true  # non-fatal
  run_step "${example}_DNS"                test_dns_configuration    || true  # non-fatal
  run_step "${example}_Destroy"            destroy_infrastructure

  log "SUCCESS" "=== Done: $example ==="
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $0 [minimal|existing-infrastructure|all]   (default: minimal)

Flags (environment variables):
  SKIP_DESTROY=true   keep Azure resources after the test
  DRY_RUN=true        print what would run without executing
  CI_MODE=true        disable terminal colours

Output:
  test-results/integration-test-report.xml  (JUnit XML for CI/CD)
  test-results/integration-test.log
  test-results/summary.txt
EOF
}

[[ "${1:-}" =~ ^(-h|--help)$ ]] && { usage; exit 0; }

main() {
  trap 'rm -f "${TEST_RESULTS_DIR}/tmp.xml"' EXIT
  init_results
  local target="${1:-minimal}"

  if [[ "$target" == "all" ]]; then
    local ok=true
    for ex in "${ALL_EXAMPLES[@]}"; do run_example "$ex" || ok=false; done
    write_report "all"
    [[ "$ok" == "true" && $TESTS_FAILED -eq 0 ]]
  elif [[ "$target" =~ ^(minimal|existing-infrastructure)$ ]]; then
    run_example "$target"
    write_report "$target"
    [[ $TESTS_FAILED -eq 0 ]]
  else
    log "ERROR" "Unknown target '$target'. Use: minimal | existing-infrastructure | all"
    exit 1
  fi
}

main "$@"
