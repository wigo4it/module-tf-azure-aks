# Egress IP alleen aanmaken bij outbound_type loadBalancer.
# Bij userDefinedRouting (UDR naar hub firewall) is geen egress public IP nodig.
resource "azurerm_public_ip" "egress_ipv4" {
  count = var.network_profile.outbound_type == "loadBalancer" ? 1 : 0

  name                = "pip-egress-ipv4-${var.name}-1"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_version          = "IPv4"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}
