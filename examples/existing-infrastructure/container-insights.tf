# De module (modules/default) beheert geen Kubernetes-resources, dus deze ConfigMap
# wordt hier op root-niveau toegepast. Nodig voor kubelogin exec-auth in provider.tf.
data "azuread_service_principal" "aks" {
  display_name = "Azure Kubernetes Service AAD Server"
}

# ContainerLog table retireert 30-09-2026 (Microsoft). Dwing ContainerLogV2 af
# zolang Container Insights (oms_agent) actief is. Zie
# https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-logs-schema
resource "kubernetes_config_map_v1" "container_azm_ms_agentconfig" {
  count = var.oms_agent_enabled ? 1 : 0

  metadata {
    name      = "container-azm-ms-agentconfig"
    namespace = "kube-system"
  }

  data = {
    schema-version                 = "v1"
    config-version                 = "1"
    "log-data-collection-settings" = <<-TOML
      [log_collection_settings.schema]
          containerlog_schema_version = "v2"
    TOML
  }
}
