# Resource group for monitoring resources (optioneel — module maakt intern een LAW aan als geen bestaande opgegeven)
resource "azurerm_resource_group" "monitoring" {
  count    = var.log_analytics_workspace_id == null ? 1 : 0
  name     = "rg-monitoring-${var.cluster_name}"
  location = var.location

  tags = {
    environment = "example"
    purpose     = "monitoring"
  }
}

# Log Analytics Workspace — alleen aanmaken als geen bestaande LAW is opgegeven
resource "azurerm_log_analytics_workspace" "aks_monitoring" {
  count               = var.log_analytics_workspace_id == null ? 1 : 0
  name                = "law-aks-${var.cluster_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.monitoring[0].name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = "example"
    purpose     = "aks-monitoring"
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

  # WAF - Operational Excellence: automatische patch-upgrades + NodeImage node OS vernieuwing
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  # Node pool — system pool met only_critical_addons zodat workloads naar user pools gaan
  aks_default_node_pool = {
    vm_size                        = var.default_node_pool_vm_size
    node_count                     = var.default_node_pool_node_count
    zones                          = ["1", "2", "3"]
    cluster_auto_scaling_enabled   = var.enable_auto_scaling
    cluster_auto_scaling_min_count = var.enable_auto_scaling ? var.min_node_count : null
    cluster_auto_scaling_max_count = var.enable_auto_scaling ? var.max_node_count : null
    node_public_ip_enabled         = false
    # WAF - Reliability: system pool alleen voor kritieke AKS add-ons
    only_critical_addons_enabled = true
    # WAF - Security: host-level encryptie en AzureLinux minimale attack surface
    host_encryption_enabled = true
    os_sku                  = "AzureLinux"
    os_disk_type            = "Ephemeral"
  }

  # WAF - Security: Azure AD RBAC — lokale accounts uitgeschakeld
  local_account_disabled = true
  aks_azure_active_directory_role_based_access_control = {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  # Optional configurations - only specify if different from defaults
  aks_additional_node_pools = var.additional_node_pools
  loadbalancer_ips          = var.loadbalancer_ips
  private_cluster_enabled   = var.private_cluster_enabled
  sku_tier                  = var.sku_tier
  prometheus_enabled        = var.prometheus_enabled

  existing_log_analytics_workspace_id = var.log_analytics_workspace_id

  # Only specify workload autoscaler if different from default (disabled)
  workload_autoscaler_profile = var.enable_keda || var.enable_vpa ? {
    keda_enabled                    = var.enable_keda
    vertical_pod_autoscaler_enabled = var.enable_vpa
  } : null
}
