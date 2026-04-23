locals {
  # DRY: private cluster with DNS zone — governs role assignments and identity type.
  private_cluster_with_dns = var.private_cluster_enabled && var.private_dns_zone_id != null
}

# User-assigned managed identity for the AKS cluster.
# Used as the cluster identity when private_cluster_enabled is true, so AKS can manage
# private DNS zones and network resources without a service principal.
resource "azurerm_user_assigned_identity" "aks_identity" {
  count = 1

  name                = "id-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "aks_identity_private_dns_zone_contributor" {
  count = local.private_cluster_with_dns ? 1 : 0

  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_identity_network_contributor" {
  count = local.private_cluster_with_dns ? 1 : 0

  scope                = var.virtual_network.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity[0].principal_id
}
