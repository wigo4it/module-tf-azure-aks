resource "azurerm_kubernetes_cluster" "default" {
  name                      = "aks-${var.name}"
  location                  = azurerm_resource_group.default.location
  resource_group_name       = azurerm_resource_group.default.name
  dns_prefix                = "aks-${var.name}"
  kubernetes_version        = var.kubernetes_version
  automatic_channel_upgrade = "patch"
  node_resource_group       = "${azurerm_resource_group.default.name}-nodes"
  sku_tier                  = "Free"

  default_node_pool {
    vnet_subnet_id              = azurerm_subnet.default.id
    name                        = "agentpool"
    temporary_name_for_rotation = "agentpooltmp"

    vm_size               = var.aks_default_node_pool.vm_size
    zones                 = var.aks_default_node_pool.zones
    max_pods              = var.aks_default_node_pool.max_pods
    os_disk_size_gb       = var.aks_default_node_pool.os_disk_size_gb
    os_disk_type          = var.aks_default_node_pool.os_disk_type
    node_labels           = var.aks_default_node_pool.labels
    node_taints           = var.aks_default_node_pool.taints
    node_count            = var.aks_default_node_pool.node_count
    enable_auto_scaling   = var.aks_default_node_pool.cluster_auto_scaling
    min_count             = var.aks_default_node_pool.cluster_auto_scaling_min_count
    max_count             = var.aks_default_node_pool.cluster_auto_scaling_max_count
    enable_node_public_ip = var.aks_default_node_pool.enable_node_public_ip
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

  api_server_access_profile {
    authorized_ip_ranges = var.aks_authorized_ip_ranges
  }
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.default.identity[0].principal_id
}
