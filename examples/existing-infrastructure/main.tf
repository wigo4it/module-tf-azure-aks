# Example: AKS cluster deployment using existing VNet and DNS zone
# This example demonstrates how to deploy an Azure Kubernetes Service (AKS) cluster
# using existing networking and DNS infrastructure with the Haven Terraform module.

data "azurerm_client_config" "current" {}

module "haven" {
  source = "../../modules/default"

  name                = "aks-${var.cluster_name}"
  location            = var.location
  resource_group_name = "rg-560x-${var.cluster_name}"

  virtual_network = {
    is_existing         = true
    id                  = azurerm_virtual_network.networking.id
    name                = azurerm_virtual_network.networking.name
    resource_group_name = azurerm_resource_group.networking.name
    subnet = {
      is_existing = true
      name        = azurerm_subnet.networking.name
    }
  }

  # Network profile — Azure CNI met Calico netwerk policy
  network_profile = {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    ip_versions       = ["IPv4"]
    outbound_type     = "loadBalancer"
  }

  kubernetes_version = var.kubernetes_version

  # WAF - Operational Excellence: automatische patch-upgrades + NodeImage node OS vernieuwing
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  aks_default_node_pool = {
    vm_size                        = var.default_node_pool_vm_size
    node_count                     = var.default_node_pool_node_count
    cluster_auto_scaling_enabled   = var.enable_auto_scaling
    cluster_auto_scaling_min_count = var.enable_auto_scaling ? var.min_node_count : null
    cluster_auto_scaling_max_count = var.enable_auto_scaling ? var.max_node_count : null
    zones                          = ["1", "2", "3"]
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
    admin_group_object_ids = [data.azurerm_client_config.current.object_id]
    azure_rbac_enabled     = true
  }

  # Optional: Add additional node pools
  aks_additional_node_pools = var.additional_node_pools

  # Optional: Configure load balancer IPs if you have specific requirements
  loadbalancer_ips = var.loadbalancer_ips

  # Optional: Configure private cluster
  private_cluster_enabled = var.private_cluster_enabled

  # Optional: Configure authorized ip ranges
  aks_authorized_ip_ranges = []

  # Optional: Configure SKU tier
  sku_tier = var.sku_tier

  prometheus_enabled = var.prometheus_enabled

  # Optional: Configure workload autoscaler
  workload_autoscaler_profile = {
    keda_enabled                    = var.enable_keda
    vertical_pod_autoscaler_enabled = var.enable_vpa
  }

  existing_log_analytics_workspace_id = var.existing_log_analytics_workspace_id

  # Explicit dependencies to ensure existing infrastructure is created first
  depends_on = [
    azurerm_virtual_network.networking,
    azurerm_subnet.networking
  ]
}
