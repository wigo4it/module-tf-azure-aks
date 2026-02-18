# =============================
# Azure Container Registry Integration
# =============================

# Grant AKS kubelet identity AcrPull permissions on the specified ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  count = var.container_registry_id != null ? 1 : 0

  principal_id                     = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.container_registry_id
  skip_service_principal_aad_check = true
}
