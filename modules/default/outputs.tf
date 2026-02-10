output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.name
}

output "resource_group_name" {
  value = var.resource_group_name
}

output "resource_group_location" {
  value = var.location
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
