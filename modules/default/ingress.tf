resource "azurerm_public_ip" "ingress_ipv4" {
  count = length(var.loadbalancer_ips) == 0 ? 1 : 0

  name                = "pip-ingress-ipv4-${var.name}-${count.index}"
  location            = local.azurerm_resource_group_location
  resource_group_name = local.azurerm_resource_group_name
  ip_version          = "IPv4"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}
