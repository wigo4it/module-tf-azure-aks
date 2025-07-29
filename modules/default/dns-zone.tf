# Create DNS zone only if existing DNS zone is not provided
# resource "azurerm_dns_zone" "default" {
#   count = var.existing_dns_zone_id == null ? 1 : 0

#   name                = var.domain_name
#   resource_group_name = azurerm_resource_group.default.name
# }

# Data source for existing DNS zone
# data "azurerm_dns_zone" "existing" {
#   count = var.existing_dns_zone_id != null ? 1 : 0

#   name                = var.domain_name
#   resource_group_name = var.existing_dns_zone_resource_group_name
# }

# Local to get the correct DNS zone values
# locals {
# #  dns_zone_name                = var.existing_dns_zone_id != null ? var.domain_name : azurerm_dns_zone.default[0].name
# #  dns_zone_resource_group_name = var.existing_dns_zone_id != null ? var.existing_dns_zone_resource_group_name : azurerm_resource_group.default.name
#   dns_zone_id                  = var.existing_dns_zone_id != null ? var.existing_dns_zone_id : azurerm_dns_zone.default[0].id
# }

# resource "azurerm_dns_a_record" "wildcard" {
#   count = var.create_dns_records ? 1 : 0

#   zone_name           = local.dns_zone_name
#   resource_group_name = local.dns_zone_resource_group_name
#   name                = "*"
#   ttl                 = 300
#   records             = length(var.loadbalancer_ips) == 0 ? azurerm_public_ip.ingress_ipv4[*].ip_address : var.loadbalancer_ips
# }

# resource "azurerm_dns_a_record" "lb" {
#   count = var.create_dns_records ? 1 : 0

#   zone_name           = local.dns_zone_name
#   resource_group_name = local.dns_zone_resource_group_name
#   name                = "lb"
#   ttl                 = 300
#   records             = length(var.loadbalancer_ips) == 0 ? azurerm_public_ip.ingress_ipv4[*].ip_address : var.loadbalancer_ips
# }

# resource "azurerm_dns_a_record" "int_wildcard" {
#   count = var.create_dns_records && var.internal_loadbalancer_ip != "" ? 1 : 0

#   zone_name           = local.dns_zone_name
#   resource_group_name = local.dns_zone_resource_group_name
#   name                = "*.int"
#   ttl                 = 300
#   records             = [var.internal_loadbalancer_ip]
# }
