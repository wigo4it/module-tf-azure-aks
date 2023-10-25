resource "azurerm_virtual_network_peering" "default" {
  for_each = toset(var.vnet_peerings)

  resource_group_name = azurerm_resource_group.default.name
  name                = "peering-${element(split("/", each.value), 8)}"

  virtual_network_name         = azurerm_virtual_network.default.name
  remote_virtual_network_id    = each.value
  allow_forwarded_traffic      = false
  allow_virtual_network_access = true
}
