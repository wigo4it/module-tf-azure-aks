resource "azurerm_user_assigned_identity" "aks_identity" {
  count = 1 # var.private_cluster_enabled && var.private_dns_zone_id != null ? 1 : 0

  name                = "id-${var.name}"
  location            = local.azurerm_resource_group_location
  resource_group_name = local.azurerm_resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_identity_private_dns_zone_contributor" {
  count = var.private_cluster_enabled && var.private_dns_zone_id != null ? 1 : 0

  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_identity_network_contributor" {
  count = var.private_cluster_enabled && var.private_dns_zone_id != null ? 1 : 0

  scope                = var.virtual_network.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity[0].principal_id
}

resource "azurerm_kubernetes_cluster" "default" {
  azure_policy_enabled              = var.azure_policy_enabled
  automatic_upgrade_channel         = var.automatic_upgrade_channel
  depends_on                        = [azurerm_role_assignment.aks_identity_network_contributor]
  disk_encryption_set_id            = var.disk_encryption_set_id
  dns_prefix                        = coalesce(var.dns_prefix, var.name)
  image_cleaner_enabled             = var.image_cleaner_enabled
  image_cleaner_interval_hours      = var.image_cleaner_interval_hours
  kubernetes_version                = var.kubernetes_version
  local_account_disabled            = var.local_account_disabled
  location                          = local.azurerm_resource_group_location
  name                              = var.name
  node_resource_group               = "${local.azurerm_resource_group_name}-nodes"
  oidc_issuer_enabled               = var.oidc_issuer_enabled
  private_cluster_enabled           = var.private_cluster_enabled
  private_dns_zone_id               = var.private_dns_zone_id
  resource_group_name               = local.azurerm_resource_group_name
  role_based_access_control_enabled = var.role_based_access_control_enabled
  sku_tier                          = var.sku_tier
  tags                              = var.tags
  workload_identity_enabled         = var.workload_identity_enabled


  # Azure Monitor for container metrics (security compliance)
  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  default_node_pool {
    auto_scaling_enabled         = var.aks_default_node_pool.cluster_auto_scaling_enabled
    max_count                    = var.aks_default_node_pool.cluster_auto_scaling_max_count
    max_pods                     = var.aks_default_node_pool.max_pods
    min_count                    = var.aks_default_node_pool.cluster_auto_scaling_min_count
    name                         = var.aks_default_node_pool.name
    node_count                   = var.aks_default_node_pool.node_count
    node_labels                  = var.aks_default_node_pool.labels
    node_public_ip_enabled       = var.aks_default_node_pool.node_public_ip_enabled
    only_critical_addons_enabled = var.aks_default_node_pool.only_critical_addons_enabled
    os_disk_size_gb              = var.aks_default_node_pool.os_disk_size_gb
    os_disk_type                 = var.aks_default_node_pool.os_disk_type
    temporary_name_for_rotation  = "${var.aks_default_node_pool.name}tmp"
    vm_size                      = var.aks_default_node_pool.vm_size
    vnet_subnet_id               = local.subnet_id

    zones = var.aks_default_node_pool.zones

    dynamic "upgrade_settings" {
      for_each = var.aks_default_node_pool.upgrade_settings != null ? ["enabled"] : []
      content {
        drain_timeout_in_minutes = var.aks_default_node_pool.upgrade_settings.drain_timeout_in_minutes
        max_surge                = var.aks_default_node_pool.upgrade_settings.max_surge
      }
    }
  }
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.aks_azure_active_directory_role_based_access_control != null ? ["enabled"] : []
    content {
      admin_group_object_ids = var.aks_azure_active_directory_role_based_access_control.admin_group_object_ids
      azure_rbac_enabled     = var.aks_azure_active_directory_role_based_access_control.azure_rbac_enabled
      tenant_id              = var.aks_azure_active_directory_role_based_access_control.tenant_id
    }
  }

  network_profile {
    ip_versions       = var.network_profile.ip_versions
    load_balancer_sku = var.network_profile.load_balancer_sku
    network_plugin    = var.network_profile.network_plugin
    network_policy    = var.network_profile.network_policy

    load_balancer_profile {
      outbound_ip_address_ids = concat(
        azurerm_public_ip.egress_ipv4[*].id,
      )
    }
  }

  identity {
    identity_ids = var.private_cluster_enabled ? [azurerm_user_assigned_identity.aks_identity[0].id] : []
    type         = var.private_cluster_enabled ? "UserAssigned" : "SystemAssigned"
  }

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

  dynamic "microsoft_defender" {
    for_each = var.microsoft_defender_enabled ? ["enabled"] : []
    content {
      log_analytics_workspace_id = local.log_analytics_workspace_id
    }
  }

  # Key Vault Secrets Provider for enhanced secret management
  dynamic "key_vault_secrets_provider" {
    for_each = var.key_vault_secrets_provider != null ? ["enabled"] : []
    content {
      secret_rotation_enabled  = var.key_vault_secrets_provider.secret_rotation_enabled
      secret_rotation_interval = var.key_vault_secrets_provider.secret_rotation_interval
    }
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      default_node_pool[0].upgrade_settings,
      kubernetes_version
    ]
  }
}

# Diagnostic settings for audit logs (security compliance)
resource "azurerm_monitor_diagnostic_setting" "aks_audit_logs" {
  count = var.enable_audit_logs ? 1 : 0

  name                       = "${var.name}-audit-logs"
  target_resource_id         = azurerm_kubernetes_cluster.default.id
  log_analytics_workspace_id = local.log_analytics_workspace_id

  dynamic "enabled_log" {
    for_each = var.aks_audit_categories
    content {
      category = enabled_log.value
    }
  }
}
