resource "azurerm_dns_zone" "default" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.default.name
}

resource "azurerm_dns_a_record" "wildcard" {
  zone_name           = azurerm_dns_zone.default.name
  resource_group_name = azurerm_resource_group.default.name
  name                = "*"
  ttl                 = 300
  records             = azurerm_public_ip.ingress_ipv4.*.ip_address
}

resource "azurerm_dns_a_record" "int_wildcard" {
  count = var.traefik_internal_loadbalancer_ip != "" ? 1 : 0

  zone_name           = azurerm_dns_zone.default.name
  resource_group_name = azurerm_resource_group.default.name
  name                = "*.int"
  ttl                 = 300
  records             = [var.traefik_internal_loadbalancer_ip]
}
