resource "azurerm_public_ip" "egress_ipv4" {
  count = 1

  name                = "pip-egress-ipv4-${var.name}-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_version          = "IPv4"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}
