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

output "cluster_storage_account_name" {
  value = azurerm_storage_account.default.name
}

output "load_balancer_ips" {
  value = azurerm_public_ip.ingress_ipv4[*].ip_address
}

output "dns_zone_name" {
  value = local.dns_zone_name
}

output "subnet_id" {
  value = local.subnet_id
}

output "cert_manager_managed_identity_client_id" {
  description = "Value for managedIdentity: clientID in ClusterIssuer"
  value       = azurerm_user_assigned_identity.cert_manager.client_id
  sensitive   = true
}
