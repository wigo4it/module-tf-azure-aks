output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.name
}

output "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster"
  value       = local.resource_group.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = local.resource_group.location
}

output "cluster_oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.default.oidc_issuer_url
}

output "load_balancer_ips" {
  value = azurerm_public_ip.ingress_ipv4[*].ip_address
}

output "subnet_id" {
  value = local.subnet_id
}

output "kubeconfig_raw" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.kube_config_raw
  sensitive   = true
}

output "kubelet_identity" {
  description = "The kubelet identity of the AKS cluster used for pulling container images"
  value = {
    object_id                 = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
    client_id                 = azurerm_kubernetes_cluster.default.kubelet_identity[0].client_id
    user_assigned_identity_id = azurerm_kubernetes_cluster.default.kubelet_identity[0].user_assigned_identity_id
  }
}

output "pod_security_policy_status" {
  description = "Status and configuration of Pod Security Standards enforcement"
  value = var.pod_security_policy.enabled ? {
    enabled             = true
    level               = var.pod_security_policy.level
    effect              = var.pod_security_policy.effect
    policy_assignment   = try(azurerm_resource_group_policy_assignment.pod_security[0].name, null)
    excluded_namespaces = var.pod_security_policy.excluded_namespaces
    recommendation      = var.pod_security_policy.effect == "audit" ? "Consider changing effect to 'deny' for production after testing" : "Pod Security Standards enforced in deny mode"
    } : {
    enabled             = false
    level               = null
    effect              = null
    policy_assignment   = null
    excluded_namespaces = []
    recommendation      = "Enable Pod Security Standards for CIS Kubernetes Benchmark compliance"
  }
}

output "monitoring_alerts_status" {
  description = "Status and configuration of Azure Monitor metric alerts"
  value = var.monitoring_alerts.enabled ? {
    enabled               = true
    alerts_configured     = ["node_cpu", "node_memory", "pod_restarts", "disk_usage", "node_not_ready", "api_server_availability"]
    action_group_count    = length(var.monitoring_alerts.action_group_ids)
    node_cpu_threshold    = "${var.monitoring_alerts.node_cpu_threshold}%"
    node_memory_threshold = "${var.monitoring_alerts.node_memory_threshold}%"
    pod_restart_threshold = var.monitoring_alerts.pod_restart_threshold
    disk_usage_threshold  = "${var.monitoring_alerts.disk_usage_threshold}%"
    recommendation        = "Monitor alerts via Azure Monitor Alerts dashboard"
    } : {
    enabled               = false
    alerts_configured     = []
    action_group_count    = 0
    node_cpu_threshold    = null
    node_memory_threshold = null
    pod_restart_threshold = null
    disk_usage_threshold  = null
    recommendation        = "Enable monitoring alerts for proactive incident prevention (+2 WAF points)"
  }
}

output "acr_role_assignment_id" {
  description = "The ID of the ACR role assignment (if ACR was attached)"
  value       = try(azurerm_role_assignment.aks_acr_pull[0].id, null)
}
