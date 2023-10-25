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
  value = azurerm_public_ip.ingress_ipv4.*.ip_address
}

output "dns_zone_name" {
  value = azurerm_dns_zone.default.name
}
