# Log Analytics Workspace for AKS monitoring (created only if existing workspace not provided)
resource "azurerm_log_analytics_workspace" "default" {
  count               = var.existing_log_analytics_workspace_id == null ? 1 : 0
  name                = "law-${var.name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# Local value to determine which Log Analytics workspace ID to use
locals {
  log_analytics_workspace_id = var.existing_log_analytics_workspace_id != null ? var.existing_log_analytics_workspace_id : (length(azurerm_log_analytics_workspace.default) > 0 ? azurerm_log_analytics_workspace.default[0].id : null)
}
