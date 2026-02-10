locals {
  # Fix the indexing issue by using proper conditional logic
  subnet_id = var.virtual_network.subnet.is_existing ? (
    length(data.azurerm_subnet.existing) > 0 ? data.azurerm_subnet.existing[0].id : null
    ) : (
    length(azurerm_subnet.default) > 0 ? azurerm_subnet.default[0].id : null
  )
}

resource "azurerm_virtual_network" "default" {
  count = var.virtual_network.is_existing ? 0 : 1

  name                = var.virtual_network.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.virtual_network.address_space
  tags                = var.tags
}

# Create subnet only if existing subnet is not provided
resource "azurerm_subnet" "default" {
  count = var.virtual_network.subnet.is_existing ? 0 : 1

  name                 = var.virtual_network.subnet.name
  resource_group_name  = var.virtual_network.is_existing ? var.virtual_network.resource_group_name : var.resource_group_name
  virtual_network_name = var.virtual_network.name
  address_prefixes     = var.virtual_network.subnet.address_prefixes
  service_endpoints    = var.virtual_network.subnet.service_endpoints
}

data "azurerm_subnet" "existing" {
  count = var.virtual_network.subnet.is_existing ? 1 : 0

  name                 = var.virtual_network.subnet.name
  virtual_network_name = var.virtual_network.name
  resource_group_name  = var.virtual_network.resource_group_name
}

resource "azurerm_virtual_network_peering" "default" {
  for_each = toset(var.virtual_network.peerings)

  resource_group_name = var.virtual_network.resource_group_name
  name                = "peering-${element(split("/", each.value), 8)}"

  virtual_network_name         = var.virtual_network.name
  remote_virtual_network_id    = each.value
  allow_forwarded_traffic      = false
  allow_virtual_network_access = true
}
