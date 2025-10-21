output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.name
}

output "resource_group_name" {
  value = azurerm_resource_group.default.name
}

output "resource_group_location" {
  value = azurerm_resource_group.default.location
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

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.default.kube_config_raw
  sensitive   = true
}
