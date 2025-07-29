resource "azurerm_user_assigned_identity" "aks_identity" {
  count = 1 # var.private_cluster_enabled && var.private_dns_zone_id != null ? 1 : 0

  name                = "id-${var.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.default.name
}

# resource "azurerm_role_assignment" "aks_identity_private_dns_zone_contributor" {
#   count = var.private_cluster_enabled && var.private_dns_zone_id != null ? 1 : 0

#   scope                = var.private_dns_zone_id
#   role_definition_name = "Private DNS Zone Contributor"
#   principal_id         = azurerm_user_assigned_identity.aks_identity[0].principal_id
# }

resource "azurerm_role_assignment" "aks_identity_network_contributor" {
  count = var.private_cluster_enabled ? 1 : 0

  scope                = var.virtual_network.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity[0].principal_id
}

resource "azurerm_kubernetes_cluster" "default" {
  depends_on = [
    #azurerm_role_assignment.aks_identity_private_dns_zone_contributor,
    azurerm_role_assignment.aks_identity_network_contributor
  ]

  name                         = var.name
  location                     = var.location
  resource_group_name          = azurerm_resource_group.default.name
  dns_prefix                   = coalesce(var.dns_prefix, "aks-${var.name}")
  kubernetes_version           = var.kubernetes_version
  automatic_upgrade_channel    = var.automatic_upgrade_channel
  node_resource_group          = "${azurerm_resource_group.default.name}-nodes"
  sku_tier                     = var.sku_tier
  private_cluster_enabled      = var.private_cluster_enabled
  private_dns_zone_id          = null #var.private_dns_zone_id
  image_cleaner_enabled        = var.image_cleaner_enabled
  image_cleaner_interval_hours = var.image_cleaner_interval_hours

  # Enable RBAC for security compliance
  role_based_access_control_enabled = true

  # Azure Monitor for container metrics (security compliance)
  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  default_node_pool {
    vnet_subnet_id              = local.subnet_id
    name                        = var.aks_default_node_pool.name
    temporary_name_for_rotation = "${var.aks_default_node_pool.name}tmp"

    vm_size                      = var.aks_default_node_pool.vm_size
    zones                        = var.aks_default_node_pool.zones
    max_pods                     = var.aks_default_node_pool.max_pods
    os_disk_size_gb              = var.aks_default_node_pool.os_disk_size_gb
    os_disk_type                 = var.aks_default_node_pool.os_disk_type
    node_labels                  = var.aks_default_node_pool.labels
    node_count                   = var.aks_default_node_pool.node_count
    auto_scaling_enabled         = var.aks_default_node_pool.cluster_auto_scaling_enabled
    min_count                    = var.aks_default_node_pool.cluster_auto_scaling_min_count
    max_count                    = var.aks_default_node_pool.cluster_auto_scaling_max_count
    node_public_ip_enabled       = var.aks_default_node_pool.node_public_ip_enabled
    only_critical_addons_enabled = var.aks_default_node_pool.only_critical_addons_enabled

    dynamic "upgrade_settings" {
      for_each = var.aks_default_node_pool.upgrade_settings != null ? [1] : []
      content {
        drain_timeout_in_minutes = var.aks_default_node_pool.upgrade_settings.drain_timeout_in_minutes
        max_surge                = var.aks_default_node_pool.upgrade_settings.max_surge
      }
    }
  }

  network_profile {
    network_plugin    = var.network_profile.network_plugin
    network_policy    = var.network_profile.network_policy
    load_balancer_sku = var.network_profile.load_balancer_sku
    ip_versions       = var.network_profile.ip_versions

    load_balancer_profile {
      outbound_ip_address_ids = concat(
        azurerm_public_ip.egress_ipv4[*].id,
      )
    }
  }

  identity {
    type         = var.private_cluster_enabled ? "UserAssigned" : "SystemAssigned"
    identity_ids = var.private_cluster_enabled ? [azurerm_user_assigned_identity.aks_identity[0].id] : []
  }

  # workload identity
  workload_identity_enabled = var.workload_identity_enabled
  oidc_issuer_enabled       = var.oidc_issuer_enabled

  workload_autoscaler_profile {
    keda_enabled                    = var.workload_autoscaler_profile != null ? var.workload_autoscaler_profile.keda_enabled : false
    vertical_pod_autoscaler_enabled = var.workload_autoscaler_profile != null ? var.workload_autoscaler_profile.vertical_pod_autoscaler_enabled : false
  }

  dynamic "api_server_access_profile" {
    for_each = var.private_cluster_enabled ? [] : ["enabled"]
    content {
      authorized_ip_ranges = var.aks_authorized_ip_ranges
    }
  }

  storage_profile {
    blob_driver_enabled         = var.storage_profile.blob_driver_enabled
    disk_driver_enabled         = var.storage_profile.disk_driver_enabled
    file_driver_enabled         = var.storage_profile.file_driver_enabled
    snapshot_controller_enabled = var.storage_profile.snapshot_controller_enabled
  }

  # Enable OMS Agent for Log Analytics monitoring (security compliance)
  oms_agent {
    log_analytics_workspace_id      = local.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      default_node_pool[0].upgrade_settings,
      kubernetes_version
    ]
  }
}
