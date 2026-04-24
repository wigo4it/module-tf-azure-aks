locals {
  # DRY: BYO CNI (network_plugin = "none") disables plugin-managed network settings.
  is_byo_cni = var.network_profile.network_plugin == "none"
}

resource "azurerm_kubernetes_cluster" "default" {
  azure_policy_enabled = var.azure_policy_enabled
  # WAF - Operational Excellence: null bij 'none' zodat AKS het attribuut niet persisteert
  automatic_upgrade_channel = var.automatic_upgrade_channel == "none" ? null : var.automatic_upgrade_channel
  # WAF - Operational Excellence: NodeImage channel hernieuwt node OS images los van Kubernetes upgrades
  node_os_upgrade_channel           = var.node_os_upgrade_channel
  disk_encryption_set_id            = var.disk_encryption_set_id
  dns_prefix                        = coalesce(var.dns_prefix, var.name)
  image_cleaner_enabled             = var.image_cleaner_enabled
  image_cleaner_interval_hours      = var.image_cleaner_interval_hours
  kubernetes_version                = var.kubernetes_version
  local_account_disabled            = var.local_account_disabled
  location                          = var.location
  name                              = var.name
  node_resource_group               = coalesce(var.node_resource_group, "${var.resource_group_name}-nodes")
  oidc_issuer_enabled               = var.oidc_issuer_enabled
  private_cluster_enabled           = var.private_cluster_enabled
  private_dns_zone_id               = var.private_dns_zone_id
  resource_group_name               = var.resource_group_name
  role_based_access_control_enabled = var.role_based_access_control_enabled
  # WAF - Security: schakel run-command uit om lateral movement via de API server te voorkomen.
  run_command_enabled       = false
  sku_tier                  = var.sku_tier
  tags                      = var.tags
  workload_identity_enabled = var.workload_identity_enabled


  # WAF - Operational Excellence: Azure Monitor metrics — schakel in via var.prometheus_enabled
  dynamic "monitor_metrics" {
    for_each = var.prometheus_enabled ? ["enabled"] : []
    content {
      annotations_allowed = null
      labels_allowed      = null
    }
  }

  default_node_pool {
    tags = var.tags

    auto_scaling_enabled = var.aks_default_node_pool.cluster_auto_scaling_enabled
    # WAF - Security: versleuteling op host-niveau voor alle node-data
    host_encryption_enabled = var.aks_default_node_pool.host_encryption_enabled
    max_count               = var.aks_default_node_pool.cluster_auto_scaling_max_count
    max_pods                = var.aks_default_node_pool.max_pods
    min_count               = var.aks_default_node_pool.cluster_auto_scaling_min_count
    name                    = var.aks_default_node_pool.name
    node_count = (
      var.aks_default_node_pool.cluster_auto_scaling_enabled &&
      var.aks_default_node_pool.cluster_auto_scaling_min_count != null &&
      var.aks_default_node_pool.node_count < var.aks_default_node_pool.cluster_auto_scaling_min_count
    ) ? var.aks_default_node_pool.cluster_auto_scaling_min_count : var.aks_default_node_pool.node_count
    node_labels            = var.aks_default_node_pool.labels
    node_public_ip_enabled = var.aks_default_node_pool.node_public_ip_enabled
    # WAF - Reliability: alleen kritieke addons op system node pool — workloads gaan naar user pools
    only_critical_addons_enabled = var.aks_default_node_pool.only_critical_addons_enabled
    # Pinnen op kubernetes_version zodat node pool en control plane altijd synchroon lopen
    orchestrator_version        = var.kubernetes_version
    os_disk_size_gb             = var.aks_default_node_pool.os_disk_size_gb
    os_disk_type                = var.aks_default_node_pool.os_disk_type
    os_sku                      = var.aks_default_node_pool.os_sku
    temporary_name_for_rotation = "${var.aks_default_node_pool.name}tmp"
    vm_size                     = var.aks_default_node_pool.vm_size
    vnet_subnet_id              = local.subnet_id
    zones                       = var.aks_default_node_pool.zones

    upgrade_settings {
      drain_timeout_in_minutes = var.aks_default_node_pool.upgrade_settings.drain_timeout_in_minutes
      max_surge                = var.aks_default_node_pool.upgrade_settings.max_surge
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
    # Bij BYO CNI (network_plugin = "none") zijn network_plugin_mode, network_policy en network_data_plane niet van toepassing.
    network_plugin_mode = local.is_byo_cni ? null : var.network_profile.network_plugin_mode
    # WAF - Security: network_data_plane 'cilium' biedt eBPF-gebaseerde network policy enforcement op kernel-niveau.
    network_data_plane = local.is_byo_cni ? null : var.network_profile.network_data_plane
    network_policy     = local.is_byo_cni ? null : var.network_profile.network_policy
    outbound_type      = var.network_profile.outbound_type
    dns_service_ip     = var.network_profile.dns_service_ip
    service_cidr       = var.network_profile.service_cidr
    # BYO CNI (network_plugin = "none"): pod_cidr niet doorgeven — Cilium beheert dit via ClusterPool IPAM.
    pod_cidr = local.is_byo_cni ? null : var.network_profile.pod_cidr

    # load_balancer_profile alleen van toepassing bij outbound_type loadBalancer
    dynamic "load_balancer_profile" {
      for_each = var.network_profile.outbound_type == "loadBalancer" ? ["enabled"] : []
      content {
        outbound_ip_address_ids = azurerm_public_ip.egress_ipv4[*].id
      }
    }

    dynamic "advanced_networking" {
      for_each = var.network_profile.advanced_networking != null ? ["enabled"] : []
      content {
        observability_enabled = var.network_profile.advanced_networking.observability_enabled
        security_enabled      = var.network_profile.advanced_networking.security_enabled
      }
    }
  }

  identity {
    identity_ids = var.private_cluster_enabled ? [azurerm_user_assigned_identity.aks_identity[0].id] : []
    type         = var.private_cluster_enabled ? "UserAssigned" : "SystemAssigned"
  }

  # WAF - Reliability: cluster autoscaler gedrag configureerbaar
  auto_scaler_profile {
    expander                      = var.auto_scaler_profile_expander
    skip_nodes_with_local_storage = var.skip_nodes_with_local_storage
  }

  workload_autoscaler_profile {
    keda_enabled                    = try(var.workload_autoscaler_profile.keda_enabled, false)
    vertical_pod_autoscaler_enabled = try(var.workload_autoscaler_profile.vertical_pod_autoscaler_enabled, false)
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

  # WAF - Operational Excellence: OMS agent voor Log Analytics — MSI auth (geen client secret)
  dynamic "oms_agent" {
    for_each = local.log_analytics_workspace_id != null ? [1] : []
    content {
      log_analytics_workspace_id      = local.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  # WAF - Security: Microsoft Defender — alleen inschakelen als LAW beschikbaar is
  dynamic "microsoft_defender" {
    for_each = var.microsoft_defender_enabled && local.log_analytics_workspace_id != null ? ["enabled"] : []
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

  timeouts {
    # Lager dan Azure DevOps pipeline timeout om state lock te voorkomen bij pipeline timeout
    update = var.timeouts_update
  }

  lifecycle {
    ignore_changes = [
      # node_count wordt beheerd door de cluster autoscaler
      default_node_pool[0].node_count,
    ]
  }
}

# Diagnostic settings for audit logs (security compliance)
resource "azurerm_monitor_diagnostic_setting" "aks_audit_logs" {
  count = var.enable_audit_logs ? 1 : 0

  name                           = "${var.name}-audit-logs"
  target_resource_id             = azurerm_kubernetes_cluster.default.id
  log_analytics_workspace_id     = local.log_analytics_workspace_id
  log_analytics_destination_type = var.log_analytics_destination_type

  dynamic "enabled_log" {
    for_each = var.aks_audit_categories
    content {
      category = enabled_log.value
    }
  }
}
