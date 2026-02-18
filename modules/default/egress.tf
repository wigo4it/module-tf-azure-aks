resource "azurerm_public_ip" "egress_ipv4" {
  name                = "pip-egress-ipv4-${var.name}-1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_version          = "IPv4"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}
