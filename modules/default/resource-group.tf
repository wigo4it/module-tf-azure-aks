data azurerm_resource_group "default" {
  name = var.resource_group_name
}

resource "azurerm_resource_group" "default" {
  count    = data.azurerm_resource_group.default.id == null ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
