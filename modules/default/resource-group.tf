data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}

resource "azurerm_resource_group" "default" {
  count    = data.azurerm_resource_group.default.id == null ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  azurerm_resource_group_name     = data.azurerm_resource_group.default.id == null ? azurerm_resource_group.default[0].name : data.azurerm_resource_group.default.name
  azurerm_resource_group_location = data.azurerm_resource_group.default.id == null ? azurerm_resource_group.default[0].location : data.azurerm_resource_group.default.location
}
