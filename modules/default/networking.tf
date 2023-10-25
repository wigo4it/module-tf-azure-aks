resource "azurerm_virtual_network" "default" {
  name                = "vnet-${var.name}"
  resource_group_name = azurerm_resource_group.default.name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.default.location
}

resource "azurerm_subnet" "default" {
  name                 = "snet-${var.name}"
  resource_group_name  = azurerm_resource_group.default.name
  virtual_network_name = azurerm_virtual_network.default.name
  address_prefixes     = var.subnet_address_prefixes
  service_endpoints = [
    "Microsoft.Storage",
  ]
}
