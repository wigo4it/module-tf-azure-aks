# resource "azurerm_user_assigned_identity" "cert_manager" {
#   resource_group_name = azurerm_resource_group.default.name
#   location            = azurerm_resource_group.default.location
#   name                = "cert-manager"
# }

# # resource "azurerm_role_assignment" "cert_manager_dns_zone_contributor" {
# #   role_definition_name = "DNS Zone Contributor"
# #   principal_id         = azurerm_user_assigned_identity.cert_manager.principal_id
# #   scope                = local.dns_zone_id
# # }

# resource "azurerm_federated_identity_credential" "cert_manager" {
#   name                = "cert-manager"
#   resource_group_name = azurerm_resource_group.default.name
#   parent_id           = azurerm_user_assigned_identity.cert_manager.id
#   issuer              = azurerm_kubernetes_cluster.default.oidc_issuer_url
#   subject             = "system:serviceaccount:cert-manager:cert-manager"
#   audience            = ["api://AzureADTokenExchange"]
# }
