# This logic queries azure to get the latest kubernetes patch version
# See Readme in root directory for explanation and reasoning
locals {
  use_version_datasource      = length(split(".", var.kubernetes_version)) == 2
  resolved_kubernetes_version = local.use_version_datasource ? data.azurerm_kubernetes_service_versions.current[0].latest_version : var.kubernetes_version
}

data "azurerm_kubernetes_service_versions" "current" {
  count           = local.use_version_datasource ? 1 : 0
  location        = var.location
  version_prefix  = var.kubernetes_version
  include_preview = false
}
