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
  features {}
}

# Data source for current Azure client configuration
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
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
# AKS Cluster with Spot Instances
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

  # System Node Pool - Regular (not spot)
  # System workloads should NOT use spot instances
  aks_default_node_pool = {
    name                           = "system"
    vm_size                        = "Standard_D2s_v5"
    node_count                     = 3
    zones                          = ["1", "2", "3"]
    mode                           = "System"
    max_pods                       = 250
    only_critical_addons_enabled   = false
    cluster_auto_scaling_enabled   = true
    cluster_auto_scaling_min_count = 3
    cluster_auto_scaling_max_count = 6
  }

  # User Node Pools with Spot Instances
  aks_additional_node_pools = {
    # Spot pool for general workloads (70-90% cost savings)
    spotuser = {
      vm_size  = "Standard_D4s_v5"
      mode     = "User"
      zones    = ["1", "2", "3"]
      max_pods = 250

      # 💰 Spot Instance Configuration
      spot_node       = true
      spot_max_price  = -1 # Pay up to regular on-demand price
      eviction_policy = "Delete"

      # Autoscaling for spot instances
      cluster_auto_scaling_enabled   = true
      cluster_auto_scaling_min_count = 2
      cluster_auto_scaling_max_count = 20

      # Label spot nodes for pod scheduling
      labels = {
        workload-type = "spot"
        cost-tier     = "low"
      }

      # Taint spot nodes - only pods with toleration will schedule here
      taints = [
        "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
      ]

      upgrade_settings = {
        drain_timeout_in_minutes = 5
        max_surge                = "33%"
      }
    }

    # Regular on-demand pool for critical workloads
    ondemand = {
      vm_size  = "Standard_D4s_v5"
      mode     = "User"
      zones    = ["1", "2", "3"]
      max_pods = 250

      cluster_auto_scaling_enabled   = true
      cluster_auto_scaling_min_count = 1
      cluster_auto_scaling_max_count = 5

      labels = {
        workload-type = "on-demand"
        cost-tier     = "standard"
      }
    }
  }

  # Security Configuration
  private_cluster_enabled           = false # Set to true for production
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

  # Workload Identity
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  tags = var.tags
}
