# Example: AKS cluster deployment using existing VNet and DNS zone
# This example demonstrates how to deploy an Azure Kubernetes Service (AKS) cluster
# using existing networking and DNS infrastructure with the Haven Terraform module.
#
# KISS Principle: This example only exposes essential configuration.
# All other settings use module's WAF-compliant defaults.

# DRY Principle: Define complex objects once in locals
locals {
  # Construct node pool configuration using sensible composition
  default_node_pool = merge(
    var.node_pool_config,
    {
      zones = ["1", "2", "3"] # Always use full 3-zone HA
    }
  )
}

module "haven" {
  source = "../../modules/default"

  # Essential configuration (SRP: only what's specific to this example)
  name                = "aks-${var.cluster_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.aks.name

  # Existing infrastructure integration
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

  kubernetes_version = var.kubernetes_version

  # Node pool uses composed local
  aks_default_node_pool = local.default_node_pool

  # WAF Security: Azure AD RBAC (local accounts disabled by module default)
  aks_azure_active_directory_role_based_access_control = {
    admin_group_object_ids = [data.azurerm_client_config.current.object_id]
    azure_rbac_enabled     = true
  }

  existing_log_analytics_workspace_id = var.existing_log_analytics_workspace_id

  # Optional: Attach Azure Container Registry
  container_registry_id = var.container_registry_id

  # WAF Security: Customer-Managed Keys for disk encryption
  disk_encryption_set_id = var.disk_encryption_set_id

  # WAF Operational Excellence: Monitoring alerts
  monitoring_alerts = var.enable_monitoring_alerts && var.monitoring_action_group_id != null ? {
    enabled               = true
    action_group_ids      = [var.monitoring_action_group_id]
    node_cpu_threshold    = 80
    node_memory_threshold = 85
    pod_restart_threshold = 5
    disk_usage_threshold  = 90
    api_server_latency_ms = 1000
    } : {
    enabled               = false
    action_group_ids      = []
    node_cpu_threshold    = 80
    node_memory_threshold = 80
    pod_restart_threshold = 5
    disk_usage_threshold  = 85
    api_server_latency_ms = 1000
  }

  # Enhanced tagging for better governance
  tags = merge(
    var.additional_tags,
    {
      deployment_method  = "terraform"
      module_name        = "module-haven-cluster-azure-digilab"
      kubernetes_version = var.kubernetes_version
      cluster_name       = var.cluster_name
    }
  )

  # Explicit dependencies to ensure existing infrastructure is created first
  depends_on = [
    azurerm_virtual_network.networking,
    azurerm_subnet.networking
  ]
}
