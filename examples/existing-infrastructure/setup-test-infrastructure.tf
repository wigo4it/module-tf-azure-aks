# This file creates dummy infrastructure for integration testing

# Resource group for the AKS cluster
resource "azurerm_resource_group" "aks" {
  name     = "rg-560x-haven-test"
  location = var.location

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "AKS Cluster"
  }
}

# Resource group for test networking infrastructure
resource "azurerm_resource_group" "networking" {
  name     = "rg-haven-networking-test"
  location = var.location

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing Infrastructure"
  }
}

# Test VNet (simulating existing infrastructure)
resource "azurerm_virtual_network" "networking" {
  name                = "vnet-haven-test"
  resource_group_name = azurerm_resource_group.networking.name
  location            = azurerm_resource_group.networking.location
  address_space       = ["10.100.0.0/16"]

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing VNet"
  }
}

# Test subnet for AKS (simulating existing infrastructure)
resource "azurerm_subnet" "networking" {
  name                 = "snet-haven-aks-test"
  resource_group_name  = azurerm_resource_group.networking.name
  virtual_network_name = azurerm_virtual_network.networking.name
  address_prefixes     = ["10.100.1.0/24"]

  # Service endpoints that AKS typically needs
  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

# Private DNS Zone for AKS private cluster
resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.westeurope.azmk8s.io"
  resource_group_name = azurerm_resource_group.networking.name

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Private DNS Zone for AKS"
  }
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "vnet-link-aks"
  resource_group_name   = azurerm_resource_group.networking.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.networking.id
  registration_enabled  = false

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Private DNS VNet Link"
  }
}

# Resource group for test DNS infrastructure
resource "azurerm_resource_group" "dns" {
  name     = "rg-haven-dns-test"
  location = var.location

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing DNS Infrastructure"
  }
}

# Test DNS zone (simulating existing infrastructure)
resource "azurerm_dns_zone" "dns" {
  name                = "haven-test.example.com"
  resource_group_name = azurerm_resource_group.dns.name

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing DNS Zone"
  }
}

# Resource group for test monitoring infrastructure
resource "azurerm_resource_group" "monitoring" {
  name     = "rg-haven-monitoring-test"
  location = var.location

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing Monitoring Infrastructure"
  }
}

# Test Log Analytics workspace (simulating existing infrastructure)
resource "azurerm_log_analytics_workspace" "monitoring" {
  name                = "law-haven-test"
  resource_group_name = azurerm_resource_group.monitoring.name
  location            = azurerm_resource_group.monitoring.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing Log Analytics Workspace"
  }
}

# Resource group for test container registry
resource "azurerm_resource_group" "acr" {
  name     = "rg-haven-acr-test"
  location = var.location

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing ACR Infrastructure"
  }
}

# Resource group for security infrastructure
resource "azurerm_resource_group" "security" {
  name     = "rg-haven-security-test"
  location = var.location

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing Security Infrastructure"
  }
}


# Key Vault for CMK encryption
resource "azurerm_key_vault" "security" {
  name                       = "kv-haven-${formatdate("YYYYMMDDhhmm", timestamp())}"
  location                   = azurerm_resource_group.security.location
  resource_group_name        = azurerm_resource_group.security.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "CMK Encryption"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# Key Vault access policy for current user
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.security.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Recover",
    "Purge",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]
}

# Encryption key for disk encryption
resource "azurerm_key_vault_key" "disk_encryption" {
  name         = "disk-encryption-key"
  key_vault_id = azurerm_key_vault.security.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [
    azurerm_key_vault_access_policy.current_user
  ]
}

# Disk Encryption Set
resource "azurerm_disk_encryption_set" "aks" {
  name                = "des-aks-test"
  resource_group_name = azurerm_resource_group.security.name
  location            = azurerm_resource_group.security.location
  key_vault_key_id    = azurerm_key_vault_key.disk_encryption.id

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Disk Encryption"
  }
}

# Grant Disk Encryption Set access to Key Vault
resource "azurerm_key_vault_access_policy" "disk_encryption_set" {
  key_vault_id = azurerm_key_vault.security.id
  tenant_id    = azurerm_disk_encryption_set.aks.identity[0].tenant_id
  object_id    = azurerm_disk_encryption_set.aks.identity[0].principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

# Resource group for monitoring infrastructure
resource "azurerm_resource_group" "monitoring_alerts" {
  name     = "rg-haven-alerts-test"
  location = var.location

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Monitoring Infrastructure"
  }
}

# Action group for monitoring alerts
resource "azurerm_monitor_action_group" "aks_alerts" {
  name                = "ag-aks-alerts-test"
  resource_group_name = azurerm_resource_group.monitoring_alerts.name
  short_name          = "aksalerts"

  email_receiver {
    name                    = "ops-team"
    email_address           = "ops@example.com"
    use_common_alert_schema = true
  }

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Alert Action Group"
  }
}

# Test Azure Container Registry (simulating existing infrastructure)
resource "azurerm_container_registry" "acr" {
  name                = "acrhaven${formatdate("YYYYMMDDhhmmss", timestamp())}"
  resource_group_name = azurerm_resource_group.acr.name
  location            = azurerm_resource_group.acr.location
  sku                 = "Standard"
  admin_enabled       = false

  tags = {
    Purpose = "Haven Integration Testing"
    Type    = "Existing Container Registry"
  }

  lifecycle {
    ignore_changes = [name]
  }
}

# Outputs for integration testing
output "test_log_analytics_workspace_id" {
  description = "ID of the test Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.monitoring.id
}

output "test_vnet_name" {
  description = "Name of the test VNet"
  value       = azurerm_virtual_network.networking.name
}

output "test_vnet_resource_group_name" {
  description = "Resource group name of the test VNet"
  value       = azurerm_resource_group.networking.name
}

output "test_subnet_name" {
  description = "Name of the test subnet"
  value       = azurerm_subnet.networking.name
}

output "test_dns_zone_name" {
  description = "Name of the test DNS zone"
  value       = azurerm_dns_zone.dns.name
}

output "test_acr_id" {
  description = "ID of the test Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "test_acr_login_server" {
  description = "Login server URL of the test Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "test_disk_encryption_set_id" {
  description = "ID of the Disk Encryption Set for CMK encryption"
  value       = azurerm_disk_encryption_set.aks.id
}

output "test_action_group_id" {
  description = "ID of the monitoring action group for alerts"
  value       = azurerm_monitor_action_group.aks_alerts.id
}
output "test_private_dns_zone_id" {
  description = "The resource ID of the private DNS zone for AKS private cluster"
  value       = azurerm_private_dns_zone.aks.id
}

output "test_resource_group_name" {
  description = "The name of the resource group where the AKS cluster will be deployed"
  value       = azurerm_resource_group.aks.name
}