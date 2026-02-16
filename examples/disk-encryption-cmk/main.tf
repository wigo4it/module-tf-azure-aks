terraform {
  required_version = ">= 1.9.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# =============================
# Key Vault for CMK
# =============================

resource "azurerm_key_vault" "aks_cmk" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  tags = var.tags
}

# Grant current user/service principal access to create keys
resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.aks_cmk.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Get",
    "List",
    "Delete",
    "Update",
    "GetRotationPolicy",
    "SetRotationPolicy"
  ]
}

# Key Vault Key for disk encryption (RSA 2048)
resource "azurerm_key_vault_key" "aks_disk_encryption" {
  name         = "aks-disk-encryption-key"
  key_vault_id = azurerm_key_vault.aks_cmk.id
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

  tags = var.tags

  depends_on = [azurerm_key_vault_access_policy.deployer]
}

# =============================
# Disk Encryption Set
# =============================

resource "azurerm_disk_encryption_set" "aks" {
  name                = "${var.cluster_name}-disk-encryption-set"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  key_vault_key_id    = azurerm_key_vault_key.aks_disk_encryption.id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# Grant Disk Encryption Set access to Key Vault key
resource "azurerm_key_vault_access_policy" "disk_encryption_set" {
  key_vault_id = azurerm_key_vault.aks_cmk.id
  tenant_id    = azurerm_disk_encryption_set.aks.identity[0].tenant_id
  object_id    = azurerm_disk_encryption_set.aks.identity[0].principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

# =============================
# Virtual Network
# =============================

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]

  tags = var.tags
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/20"]

  service_endpoints = [
    "Microsoft.Storage",
    "Microsoft.KeyVault",
    "Microsoft.ContainerRegistry"
  ]
}

# =============================
# AKS Cluster with CMK Encryption
# =============================

module "aks_cluster" {
  source = "../../modules/default"

  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  kubernetes_version  = var.kubernetes_version

  # Virtual Network Configuration
  virtual_network = {
    name                = azurerm_virtual_network.vnet.name
    resource_group_name = azurerm_resource_group.rg.name
    address_space       = azurerm_virtual_network.vnet.address_space
    is_existing         = true
    id                  = azurerm_virtual_network.vnet.id
    subnet = {
      name             = azurerm_subnet.aks_subnet.name
      address_prefixes = azurerm_subnet.aks_subnet.address_prefixes
      is_existing      = true
    }
  }

  # Default System Node Pool with CMK encryption
  aks_default_node_pool = {
    name                           = "system"
    vm_size                        = "Standard_DC2ads_v6"
    node_count                     = 3
    zones                          = ["1", "2", "3"]
    mode                           = "System"
    max_pods                       = 250
    only_critical_addons_enabled   = false
    cluster_auto_scaling_enabled   = true
    cluster_auto_scaling_min_count = 3
    cluster_auto_scaling_max_count = 6
  }

  # Additional User Node Pool
  aks_additional_node_pools = {
    user = {
      vm_size                        = "Standard_D4s_v5"
      node_count                     = 3
      zones                          = ["1", "2", "3"]
      mode                           = "User"
      max_pods                       = 250
      cluster_auto_scaling_enabled   = true
      cluster_auto_scaling_min_count = 2
      cluster_auto_scaling_max_count = 10
    }
  }

  # 🔒 Customer-Managed Key Disk Encryption
  disk_encryption_set_id = azurerm_disk_encryption_set.aks.id

  # Security Configuration
  private_cluster_enabled           = true
  local_account_disabled            = true
  microsoft_defender_enabled        = true
  role_based_access_control_enabled = true

  # Azure AD RBAC
  aks_azure_active_directory_role_based_access_control = {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
  }

  # Network Configuration (Azure CNI Overlay)
  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }

  # Monitoring & Logging
  enable_audit_logs = true
  sku_tier          = "Standard"

  # Key Vault Integration
  key_vault_secrets_provider = {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Workload Identity
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags

  depends_on = [
    azurerm_key_vault_access_policy.disk_encryption_set
  ]
}
