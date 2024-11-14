resource "azurerm_kubernetes_cluster" "default" {
  name                      = "aks-${var.name}"
  location                  = azurerm_resource_group.default.location
  resource_group_name       = azurerm_resource_group.default.name
  dns_prefix                = "aks-${var.name}"
  kubernetes_version        = var.kubernetes_version
  automatic_channel_upgrade = "patch"
  node_resource_group       = "${azurerm_resource_group.default.name}-nodes"
  sku_tier                  = "Free"
  private_cluster_enabled = var.private_cluster_enabled

  default_node_pool {
    vnet_subnet_id              = azurerm_subnet.default.id
    name                        = "agentpool"
    temporary_name_for_rotation = "agentpooltmp"

    vm_size                      = var.aks_default_node_pool.vm_size
    zones                        = var.aks_default_node_pool.zones
    max_pods                     = var.aks_default_node_pool.max_pods
    os_disk_size_gb              = var.aks_default_node_pool.os_disk_size_gb
    os_disk_type                 = var.aks_default_node_pool.os_disk_type
    node_labels                  = var.aks_default_node_pool.labels
    node_count                   = var.aks_default_node_pool.node_count
    enable_auto_scaling          = var.aks_default_node_pool.cluster_auto_scaling
    min_count                    = var.aks_default_node_pool.cluster_auto_scaling_min_count
    max_count                    = var.aks_default_node_pool.cluster_auto_scaling_max_count
    enable_node_public_ip        = var.aks_default_node_pool.enable_node_public_ip
    only_critical_addons_enabled = var.aks_default_node_pool.only_critical_addons_enabled

    upgrade_settings {
      drain_timeout_in_minutes = 5
      max_surge                = "10%"
    }
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    ip_versions       = ["IPv4"]

    load_balancer_profile {
      outbound_ip_address_ids = concat(
        azurerm_public_ip.egress_ipv4.*.id,
      )
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # workload identity
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  workload_autoscaler_profile {
    keda_enabled                    = var.workload_autoscaler_profile.keda_enabled
    vertical_pod_autoscaler_enabled = var.workload_autoscaler_profile.vertical_pod_autoscaler_enabled
  }

  api_server_access_profile {
    authorized_ip_ranges = var.aks_authorized_ip_ranges
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      default_node_pool[0].upgrade_settings,
      kubernetes_version
    ]
  }
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.default.identity[0].principal_id
}
