# Resource group for monitoring resources
resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring-${var.cluster_name}"
  location = var.location

  tags = {
    Environment = "cilium-example"
    Purpose     = "monitoring"
  }
}

# Log Analytics Workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "aks_monitoring" {
  name                = "law-aks-${var.cluster_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "cilium-example"
    Purpose     = "aks-monitoring"
  }
}

# AKS cluster using Azure CNI powered by Cilium
# network_data_plane = "cilium" enables the managed Cilium solution
# network_plugin_mode = "overlay" uses Cilium in overlay mode (no pod subnet required)
# advanced_networking enables Cilium observability and security features

module "haven" {
  source = "../../modules/default"

  # Basic cluster identification
  name                = var.cluster_name
  location            = var.location
  resource_group_name = "rg-${var.cluster_name}"

  virtual_network = {
    is_existing         = false
    name                = "vnet-${var.cluster_name}"
    resource_group_name = "rg-${var.cluster_name}"
    address_space       = var.vnet_address_space
    peerings            = var.vnet_peerings
    subnet = {
      name             = "subnet-${var.cluster_name}"
      address_prefixes = var.subnet_address_prefixes
    }
  }

  kubernetes_version = var.kubernetes_version

  # Node pool configuration
  aks_default_node_pool = {
    vm_size                        = var.default_node_pool_vm_size
    node_count                     = var.default_node_pool_node_count
    zones                          = ["1", "2", "3"]
    cluster_auto_scaling_enabled   = var.enable_auto_scaling
    cluster_auto_scaling_min_count = var.enable_auto_scaling ? var.min_node_count : null
    cluster_auto_scaling_max_count = var.enable_auto_scaling ? var.max_node_count : null
    node_public_ip_enabled         = false
  }

  # Azure CNI powered by Cilium network configuration
  network_profile = {
    network_plugin      = "azure"
    network_data_plane  = "cilium"
    network_policy      = "cilium"
    network_plugin_mode = "overlay"
    pod_cidr            = var.pod_cidr
    load_balancer_sku   = "standard"
    ip_versions         = ["IPv4"]
    advanced_networking = {
      observability_enabled = var.cilium_observability_enabled
      security_enabled      = var.cilium_security_enabled
    }
  }

  # Optional configurations
  aks_additional_node_pools = var.additional_node_pools
  loadbalancer_ips          = var.loadbalancer_ips
  private_cluster_enabled   = var.private_cluster_enabled
  sku_tier                  = var.sku_tier

  workload_autoscaler_profile = var.enable_keda || var.enable_vpa ? {
    keda_enabled                    = var.enable_keda
    vertical_pod_autoscaler_enabled = var.enable_vpa
  } : null
}
