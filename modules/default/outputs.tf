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
  value = azurerm_dns_zone.default.name
}

output "subnet_id" {
  value = azurerm_subnet.default.id
}

output "dns_zone_name_servers" {
  value = azurerm_dns_zone.default.name_servers
}
output "cert_manager_managed_identity_client_id" {
  description = "Value for managedIdentity: clientID in ClusterIssuer"
  value       = azurerm_user_assigned_identity.cert_manager.client_id
}
