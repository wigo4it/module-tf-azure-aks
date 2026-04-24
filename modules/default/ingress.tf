# Ingress public IP alleen aanmaken bij publieke clusters zonder vooraf opgegeven IPs.
# Bij een privé cluster verloopt ingress via een internal load balancer (service-annotatie); geen public IP nodig.
resource "azurerm_public_ip" "ingress_ipv4" {
  count = !var.private_cluster_enabled && length(var.loadbalancer_ips) == 0 ? 1 : 0

  name                = "pip-ingress-ipv4-${var.name}-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  ip_version          = "IPv4"
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = var.tags
}
