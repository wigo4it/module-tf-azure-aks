output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace used for monitoring"
  value       = azurerm_log_analytics_workspace.monitoring.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.haven.cluster_name
}

output "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster"
  value       = module.haven.resource_group_name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = module.haven.resource_group_location
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster (useful for workload identity)"
  value       = module.haven.cluster_oidc_issuer_url
}

output "cluster_storage_account_name" {
  description = "Name of the storage account created for the cluster"
  value       = module.haven.cluster_storage_account_name
}

output "load_balancer_ips" {
  description = "Load balancer IP addresses"
  value       = module.haven.load_balancer_ips
}

output "dns_zone_name" {
  description = "Name of the DNS zone (existing one that was used)"
  value       = module.haven.dns_zone_name
}

output "subnet_id" {
  description = "ID of the subnet used by the cluster (existing one that was used)"
  value       = module.haven.subnet_id
}

output "cert_manager_managed_identity_client_id" {
  description = "Client ID of the managed identity for cert-manager"
  value       = module.haven.cert_manager_managed_identity_client_id
}
