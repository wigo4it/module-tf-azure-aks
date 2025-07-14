# This file creates dummy infrastructure for integration testing

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
