output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks_cluster.cluster_id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks_cluster.cluster_name
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = module.aks_cluster.cluster_fqdn
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.aks_cmk.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.aks_cmk.name
}

output "key_vault_key_id" {
  description = "The ID of the Key Vault encryption key"
  value       = azurerm_key_vault_key.aks_disk_encryption.id
}

output "disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set"
  value       = azurerm_disk_encryption_set.aks.id
}

output "disk_encryption_set_name" {
  description = "The name of the Disk Encryption Set"
  value       = azurerm_disk_encryption_set.aks.name
}

output "encryption_status" {
  description = "Status of CMK disk encryption configuration"
  value = {
    enabled                    = true
    disk_encryption_set_id     = azurerm_disk_encryption_set.aks.id
    key_vault_name             = azurerm_key_vault.aks_cmk.name
    key_name                   = azurerm_key_vault_key.aks_disk_encryption.name
    purge_protection_enabled   = azurerm_key_vault.aks_cmk.purge_protection_enabled
    soft_delete_retention_days = azurerm_key_vault.aks_cmk.soft_delete_retention_days
  }
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${module.aks_cluster.cluster_name}"
}
