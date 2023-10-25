resource "azurerm_storage_account" "default" {
  name                     = "aks${replace(var.name, "-", "")}"
  resource_group_name      = azurerm_resource_group.default.name
  location                 = azurerm_resource_group.default.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
  access_tier              = "Cool"
}
