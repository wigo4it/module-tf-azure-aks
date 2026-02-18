# =============================
# Pod Security Standards via Azure Policy
# =============================
# This file implements Pod Security Standards enforcement using Azure Policy for Kubernetes.
# It provides defense-in-depth security by blocking or auditing non-compliant pod deployments.
#
# References:
# - https://learn.microsoft.com/azure/aks/use-azure-policy
# - https://kubernetes.io/docs/concepts/security/pod-security-standards/
# - CIS Kubernetes Benchmark Section 5.2

# Azure Policy initiative IDs for Pod Security Standards
locals {
  pod_security_initiatives = {
    baseline = {
      id   = "/providers/Microsoft.Authorization/policySetDefinitions/a8640138-9b0a-4a28-b8cb-1666c838647d"
      name = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
    }
    restricted = {
      id   = "/providers/Microsoft.Authorization/policySetDefinitions/42b8ef37-b724-4e24-bbc8-7a7708edfe00"
      name = "Kubernetes cluster pod security restricted standards for Linux-based workloads"
    }
  }

  # Determine which initiative to apply
  selected_initiative = var.pod_security_policy.level == "disabled" ? null : (
    var.pod_security_policy.level == "restricted" ?
    local.pod_security_initiatives.restricted :
    local.pod_security_initiatives.baseline
  )

  # Automatically exclude system namespaces
  default_excluded_namespaces = [
    "kube-system",
    "gatekeeper-system",
    "azure-arc",
    "kube-public",
    "kube-node-lease"
  ]

  # Combine default and user-specified excluded namespaces
  all_excluded_namespaces = distinct(concat(
    local.default_excluded_namespaces,
    var.pod_security_policy.excluded_namespaces
  ))
}

# Azure Policy Assignment for Pod Security Standards
resource "azurerm_resource_group_policy_assignment" "pod_security" {
  count = var.pod_security_policy.enabled && var.pod_security_policy.level != "disabled" ? 1 : 0

  name                 = "${var.name}-pod-security-${var.pod_security_policy.level}"
  display_name         = "AKS Pod Security Standards - ${title(var.pod_security_policy.level)} (${title(var.pod_security_policy.effect)})"
  description          = "Enforces ${title(var.pod_security_policy.level)} Pod Security Standards on AKS cluster ${var.name} using ${var.pod_security_policy.effect} mode. Automatically excludes system namespaces. Learn more: https://learn.microsoft.com/azure/aks/use-azure-policy"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = local.selected_initiative.id
  location             = var.location

  # Parameters for the policy initiative
  parameters = jsonencode({
    effect = {
      value = title(var.pod_security_policy.effect) # Azure Policy expects "Audit" or "Deny"
    }
    excludedNamespaces = {
      value = local.all_excluded_namespaces
    }
  })

  # Identity for policy remediation (if needed)
  identity {
    type = "SystemAssigned"
  }

  # Ensure the AKS cluster and resource group exist first
  depends_on = [
    azurerm_kubernetes_cluster.default,
    local.resource_group
  ]
}
