resource "azurerm_public_ip" "ingress_ipv4" {
  count = length(var.loadbalancer_ips) == 0 ? 1 : 0

  name                = "pip-ingress-ipv4-${var.name}-${count.index}"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  ip_version          = "IPv4"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}
