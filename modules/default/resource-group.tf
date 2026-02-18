# Determine if we need to create a resource group or use an existing one
locals {
  create_resource_group = var.resource_group_name == null
  resource_group_name   = var.resource_group_name != null ? var.resource_group_name : "rg-${var.name}"
}

# Resource Group for AKS cluster (created if resource_group_name is null)
resource "azurerm_resource_group" "rg" {
  count = local.create_resource_group ? 1 : 0

  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

# Data source for existing resource group (used if resource_group_name is provided)
data "azurerm_resource_group" "existing" {
  count = local.create_resource_group ? 0 : 1

  name = var.resource_group_name
}

# Local variable to reference the resource group (either created or existing)
locals {
  resource_group = local.create_resource_group ? azurerm_resource_group.rg[0] : data.azurerm_resource_group.existing[0]
}
