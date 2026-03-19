output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.name
}

# Alias voor consistentie met akscluster module interface
output "resource_id" {
  description = "The resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.default.id
}

output "node_resource_group_name" {
  description = "The node resource group name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.default.node_resource_group
}

output "kubernetes_cluster_resourcegroup_name" {
  description = "The resource group name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.default.resource_group_name
}

output "aks_system_managed_identity" {
  description = "The principal ID of the AKS cluster managed identity."
  value       = azurerm_kubernetes_cluster.default.identity[0].principal_id
}

output "kube_config" {
  description = "The kube config of the AKS cluster."
  value       = azurerm_kubernetes_cluster.default.kube_config[0]
  sensitive   = true
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
