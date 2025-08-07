resource "azurerm_kubernetes_cluster_node_pool" "userpool" {
  for_each = var.aks_additional_node_pools

  kubernetes_cluster_id = azurerm_kubernetes_cluster.default.id
  vnet_subnet_id        = local.subnet_id
  orchestrator_version  = var.kubernetes_version

  name                   = substr(each.key, 0, 12)
  vm_size                = each.value.vm_size
  zones                  = each.value.zones
  mode                   = each.value.mode
  max_pods               = each.value.max_pods
  os_disk_size_gb        = each.value.os_disk_size_gb
  os_disk_type           = each.value.os_disk_type
  node_labels            = each.value.labels
  node_taints            = each.value.taints
  priority               = each.value.spot_node ? "Spot" : "Regular"
  spot_max_price         = each.value.spot_max_price
  eviction_policy        = each.value.eviction_policy
  auto_scaling_enabled   = each.value.cluster_auto_scaling_enabled
  min_count              = each.value.cluster_auto_scaling_min_count
  max_count              = each.value.cluster_auto_scaling_max_count
  node_public_ip_enabled = each.value.node_public_ip_enabled
  tags                   = var.tags

  dynamic "upgrade_settings" {
    for_each = var.aks_additional_node_pools.upgrade_settings != null ? ["enabled"] : []
    content {
      drain_timeout_in_minutes = var.aks_additional_node_pools.upgrade_settings.drain_timeout_in_minutes
      max_surge                = var.aks_deaks_additional_node_poolsfault_node_pool.upgrade_settings.max_surge
    }
  }

  lifecycle {
    ignore_changes = [node_count]
  }
}
