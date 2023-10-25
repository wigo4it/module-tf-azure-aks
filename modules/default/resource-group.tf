resource "azurerm_resource_group" "default" {
  name     = "rg-${var.name}"
  location = "West Europe"
}
