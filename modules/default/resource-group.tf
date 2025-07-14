resource "azurerm_resource_group" "default" {
  name     = coalesce(var.resource_group_name, "rg-${var.name}")
  location = var.location
}
