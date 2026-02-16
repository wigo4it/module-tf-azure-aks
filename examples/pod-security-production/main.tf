# Resource group for monitoring
resource "azurerm_resource_group" "monitoring" {
  name     = "rg-monitoring-${var.cluster_name}"
  location = var.location

  tags = {
    Environment = "production"
    Purpose     = "aks-monitoring"
    Example     = "pod-security-standards"
  }
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "aks_monitoring" {
  name                = "law-aks-${var.cluster_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.monitoring.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "production"
    Purpose     = "aks-monitoring"
    Example     = "pod-security-standards"
  }
}

# AKS Cluster with Pod Security Standards
module "aks_pod_security" {
  source = "../../modules/default"

  # Basic cluster identification
  name                = var.cluster_name
  location            = var.location
  resource_group_name = "rg-${var.cluster_name}"

  # Virtual network configuration
  virtual_network = {
    is_existing         = false
    name                = "vnet-${var.cluster_name}"
    resource_group_name = "rg-${var.cluster_name}"
    address_space       = var.vnet_address_space
    subnet = {
      name             = "subnet-${var.cluster_name}"
      address_prefixes = var.subnet_address_prefixes
    }
  }

  # Kubernetes version
  kubernetes_version = var.kubernetes_version

  # Network profile - Azure CNI Overlay
  network_profile = var.network_profile

  # 🔒 Pod Security Standards - Production configuration
  pod_security_policy = var.pod_security_policy

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

  # Security settings
  private_cluster_enabled = var.private_cluster_enabled
  sku_tier                = var.sku_tier

  # Monitoring
  existing_log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_monitoring.id

  depends_on = [
    azurerm_log_analytics_workspace.aks_monitoring
  ]
}
