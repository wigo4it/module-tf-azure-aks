# Resource group for monitoring resources
resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring-${var.cluster_name}"
  location = var.location

  tags = {
    Environment = "minimal-example"
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
    Environment = "minimal-example"
    Purpose     = "aks-monitoring"
  }
}

# Optimized minimal AKS cluster deployment using shared configuration
# This demonstrates DRY principles by reusing common Haven-compliant settings

module "haven" {
  source = "../../modules/default"

  # Basic cluster identification
  name                = var.cluster_name
  location            = var.location
  resource_group_name = "rg-${var.cluster_name}"

  virtual_network = {
    is_existing         = false # false is the default value but used in this example to set explicitly
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

  # Network profile configuration
  network_profile = var.network_profile

  # Pod Security Standards configuration
  pod_security_policy = var.pod_security_policy

  # Node pool configuration with good defaults
  aks_default_node_pool = {
    vm_size                        = var.default_node_pool_vm_size
    node_count                     = var.default_node_pool_node_count
    zones                          = ["1", "2", "3"]
    cluster_auto_scaling_enabled   = var.enable_auto_scaling
    cluster_auto_scaling_min_count = var.enable_auto_scaling ? var.min_node_count : null
    cluster_auto_scaling_max_count = var.enable_auto_scaling ? var.max_node_count : null
    node_public_ip_enabled         = false
  }

  # Optional configurations - only specify if different from defaults
  aks_additional_node_pools = var.additional_node_pools
  loadbalancer_ips          = var.loadbalancer_ips
  private_cluster_enabled   = var.private_cluster_enabled
  sku_tier                  = var.sku_tier

  # Only specify workload autoscaler if different from default (disabled)
  workload_autoscaler_profile = var.enable_keda || var.enable_vpa ? {
    keda_enabled                    = var.enable_keda
    vertical_pod_autoscaler_enabled = var.enable_vpa
  } : null
}
