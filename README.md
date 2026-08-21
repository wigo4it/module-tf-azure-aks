# Terraform module: Haven

This module sets up all needed to run a Haven-compliant Kubernetes cluster in Azure.
It includes networking, DNS, AKS and Workload Identity configuration.

## Managing Kubernetes versions

The module resolves Kubernetes versions with a clear two-mode strategy.
If kubernetes_version is major.minor (for example 1.36), it queries Azure for the latest GA patch in that minor and uses that resolved value.
If kubernetes_version is a full version (for example 1.36.3), it uses that exact value.

That resolved version is applied to both the AKS control plane (kubernetes_version) and the default node pool (orchestrator_version), so control plane and nodes stay aligned from code.

automatic_upgrade_channel is handled explicitly:

"none" is translated to null, so AKS auto-upgrade channel is disabled and versioning is fully managed by tf.
"patch", "stable", "rapid", or "node-image" are passed through to AKS, enabling platform-managed upgrades according to that channel policy.

In practice, this means:

Use none for deterministic, tf-controlled upgrades.
Use a non-none channel when you want AKS to perform automatic upgrades.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.80 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.58.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [azurerm_kubernetes_cluster.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.userpool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_log_analytics_workspace.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_diagnostic_setting.aks_audit_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_public_ip.egress_ipv4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.ingress_ipv4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_role_assignment.aks_identity_network_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.aks_identity_private_dns_zone_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_user_assigned_identity.aks_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_kubernetes_service_versions.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/kubernetes_service_versions) | data source |
| [azurerm_subnet.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_aks_additional_node_pools"></a> [aks\_additional\_node\_pools](#input\_aks\_additional\_node\_pools) | (Optional) Map of additional node pools to create for the AKS cluster. | <pre>map(object({<br/>    vm_size                     = string<br/>    node_count                  = optional(number, 1)<br/>    zones                       = optional(list(string), ["1", "3"])<br/>    mode                        = optional(string, "System")<br/>    max_pods                    = optional(number, 120)<br/>    labels                      = optional(map(string), {})<br/>    taints                      = optional(list(string), [])<br/>    spot_node                   = optional(bool, false)<br/>    spot_max_price              = optional(number, null)<br/>    eviction_policy             = optional(string, null)<br/>    os_disk_size_gb             = optional(number, null)<br/>    os_disk_type                = optional(string, "Ephemeral")<br/>    temporary_name_for_rotation = optional(string, null)<br/>    # WAF - Security: AzureLinux (Mariner) — minimale attack surface, CIS-hardened<br/>    os_sku = optional(string, "AzureLinux")<br/>    # WAF - Security: versleuteling op host-niveau voor alle node-data<br/>    host_encryption_enabled        = optional(bool, true)<br/>    cluster_auto_scaling_enabled   = optional(bool, false)<br/>    cluster_auto_scaling_min_count = optional(number, null)<br/>    cluster_auto_scaling_max_count = optional(number, null)<br/>    node_public_ip_enabled         = optional(bool, false)<br/>    upgrade_settings = optional(object({<br/>      drain_timeout_in_minutes = number<br/>      max_surge                = string<br/>      }), {<br/>      drain_timeout_in_minutes = 5<br/>      max_surge                = "33%"<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_aks_audit_categories"></a> [aks\_audit\_categories](#input\_aks\_audit\_categories) | (Optional) List of audit categories to enable for the AKS cluster. This is recommended for security compliance. | `list(string)` | <pre>[<br/>  "kube-apiserver",<br/>  "kube-audit",<br/>  "kube-audit-admin",<br/>  "kube-controller-manager",<br/>  "kube-scheduler",<br/>  "cluster-autoscaler",<br/>  "guard",<br/>  "csi-azuredisk-controller",<br/>  "csi-azurefile-controller",<br/>  "csi-snapshot-controller"<br/>]</pre> | no |
| <a name="input_aks_authorized_ip_ranges"></a> [aks\_authorized\_ip\_ranges](#input\_aks\_authorized\_ip\_ranges) | (Optional) List of authorized IP ranges for API server access. For security compliance, specify your organization's IP ranges. | `list(string)` | <pre>[<br/>  "10.0.0.0/8",<br/>  "172.16.0.0/12",<br/>  "192.168.0.0/16"<br/>]</pre> | no |
| <a name="input_aks_azure_active_directory_role_based_access_control"></a> [aks\_azure\_active\_directory\_role\_based\_access\_control](#input\_aks\_azure\_active\_directory\_role\_based\_access\_control) | (Optional) Azure Active Directory integration for RBAC. Required when local\_account\_disabled is true. | <pre>object({<br/>    admin_group_object_ids = list(string)<br/>    azure_rbac_enabled     = bool<br/>    tenant_id              = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_aks_default_node_pool"></a> [aks\_default\_node\_pool](#input\_aks\_default\_node\_pool) | (Required) Configuration for the default node pool in the AKS cluster. | <pre>object({<br/>    name            = optional(string, "default")<br/>    vm_size         = string<br/>    node_count      = optional(number, 1)<br/>    zones           = optional(list(string), ["1", "2", "3"])<br/>    max_pods        = optional(number, 120)<br/>    labels          = optional(map(string), {})<br/>    os_disk_size_gb = optional(number, null)<br/>    os_disk_type    = optional(string, "Ephemeral")<br/>    # WAF - Security: AzureLinux (Mariner) — minimale attack surface, CIS-hardened<br/>    os_sku = optional(string, "AzureLinux")<br/>    # WAF - Security: versleuteling op host-niveau voor alle node-data<br/>    host_encryption_enabled        = optional(bool, true)<br/>    cluster_auto_scaling_enabled   = optional(bool, false)<br/>    cluster_auto_scaling_min_count = optional(number, null)<br/>    cluster_auto_scaling_max_count = optional(number, null)<br/>    node_public_ip_enabled         = optional(bool, false)<br/>    # WAF - Reliability: alleen kritieke addons op system node pool<br/>    only_critical_addons_enabled = optional(bool, true)<br/>    upgrade_settings = optional(object({<br/>      drain_timeout_in_minutes = number<br/>      max_surge                = string<br/>      }), {<br/>      drain_timeout_in_minutes = 5<br/>      max_surge                = "33%"<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_auto_scaler_profile_expander"></a> [auto\_scaler\_profile\_expander](#input\_auto\_scaler\_profile\_expander) | (Optional) Expander to use for the cluster autoscaler. Possible values are least-waste, priority, most-pods and random. Defaults to priority. | `string` | `"priority"` | no |
| <a name="input_automatic_upgrade_channel"></a> [automatic\_upgrade\_channel](#input\_automatic\_upgrade\_channel) | (Optional) The automatic upgrade channel for the AKS cluster. Use 'none' to ensure the version (including patch versions) are fully managed by code. Using patch, stable or rapid will likely cause drift, because AKS auto-upgrade policy can conflict with the version pinned in code. | `string` | `"none"` | no |
| <a name="input_azure_policy_enabled"></a> [azure\_policy\_enabled](#input\_azure\_policy\_enabled) | (Optional) Should the Azure Policy Add-On be enabled? For more details please visit Understand Azure Policy for Azure Kubernetes Service. Defaults to true. | `bool` | `true` | no |
| <a name="input_disk_encryption_set_id"></a> [disk\_encryption\_set\_id](#input\_disk\_encryption\_set\_id) | (Optional) The ID of the Disk Encryption Set which should be used for the Nodes and Volumes. More information can be found in the documentation. | `string` | `null` | no |
| <a name="input_dns_prefix"></a> [dns\_prefix](#input\_dns\_prefix) | (Optional) The DNS prefix for the AKS cluster. This will be used to create the DNS records. | `string` | `null` | no |
| <a name="input_enable_audit_logs"></a> [enable\_audit\_logs](#input\_enable\_audit\_logs) | (Optional) Enable audit logs for security compliance. This is recommended for production clusters. | `bool` | `true` | no |
| <a name="input_existing_log_analytics_workspace_id"></a> [existing\_log\_analytics\_workspace\_id](#input\_existing\_log\_analytics\_workspace\_id) | (Optional) ID of existing Log Analytics workspace to use for AKS monitoring. If not provided, a new workspace will be created. | `string` | `null` | no |
| <a name="input_image_cleaner_enabled"></a> [image\_cleaner\_enabled](#input\_image\_cleaner\_enabled) | (Optional) Enable image cleaner to remove unused images from the AKS cluster. | `bool` | `true` | no |
| <a name="input_image_cleaner_interval_hours"></a> [image\_cleaner\_interval\_hours](#input\_image\_cleaner\_interval\_hours) | (Optional) Interval in hours for the image cleaner to run. | `number` | `48` | no |
| <a name="input_key_vault_secrets_provider"></a> [key\_vault\_secrets\_provider](#input\_key\_vault\_secrets\_provider) | (Optional) Key Vault Secrets Provider configuration for enhanced secret management. | <pre>object({<br/>    secret_rotation_enabled  = bool<br/>    secret_rotation_interval = string<br/>  })</pre> | <pre>{<br/>  "secret_rotation_enabled": true,<br/>  "secret_rotation_interval": "2m"<br/>}</pre> | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | (Required) The Kubernetes version to use for the AKS cluster. Value is effectively ignored if automatic\_upgrade\_channel is set to 'patch', 'stable', or 'rapid'. | `string` | n/a | yes |
| <a name="input_loadbalancer_ips"></a> [loadbalancer\_ips](#input\_loadbalancer\_ips) | (Optional) The loadbalancer IP address(es) of the public ingress controller. If not provided, an azurerm\_public\_ip will be created. | `list(string)` | `[]` | no |
| <a name="input_local_account_disabled"></a> [local\_account\_disabled](#input\_local\_account\_disabled) | (Optional) Disable local accounts for security compliance. Defaults to true (WAF - Security: geen lokale admin accounts). | `bool` | `true` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) Azure region where resources will be created. | `string` | n/a | yes |
| <a name="input_log_analytics_destination_type"></a> [log\_analytics\_destination\_type](#input\_log\_analytics\_destination\_type) | (Optional) Possible values are AzureDiagnostics and Dedicated. When set to Dedicated, logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table. | `string` | `"Dedicated"` | no |
| <a name="input_maintenance_window_auto_upgrade"></a> [maintenance\_window\_auto\_upgrade](#input\_maintenance\_window\_auto\_upgrade) | (Optional) Onderhoudsvenster voor de cluster-auto-upgrade (patch/stable/rapid/node-image). Null = geen beperking. | <pre>object({<br/>    frequency    = string<br/>    interval     = number<br/>    duration     = number<br/>    start_time   = optional(string)<br/>    utc_offset   = optional(string, "+00:00")<br/>    day_of_week  = optional(string)<br/>    day_of_month = optional(number)<br/>    week_index   = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_maintenance_window_node_os"></a> [maintenance\_window\_node\_os](#input\_maintenance\_window\_node\_os) | (Optional) Onderhoudsvenster voor node OS-upgrades (NodeImage/SecurityPatch). Null = geen beperking. | <pre>object({<br/>    frequency    = string           # "Daily" | "Weekly" | "AbsoluteMonthly" | "RelativeMonthly"<br/>    interval     = number           # herhaling, bijv. 1 = elke dag/week<br/>    duration     = number           # duur in uren (4-24)<br/>    start_time   = optional(string) # "HH:MM" in de timezone van utc_offset<br/>    utc_offset   = optional(string, "+00:00")<br/>    day_of_week  = optional(string) # vereist bij frequency = "Weekly"<br/>    day_of_month = optional(number) # vereist bij frequency = "AbsoluteMonthly"<br/>    week_index   = optional(string) # vereist bij frequency = "RelativeMonthly"<br/>  })</pre> | `null` | no |
| <a name="input_microsoft_defender_enabled"></a> [microsoft\_defender\_enabled](#input\_microsoft\_defender\_enabled) | (Optional) Enable Microsoft Defender for Containers | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the AKS cluster. | `string` | n/a | yes |
| <a name="input_network_profile"></a> [network\_profile](#input\_network\_profile) | (Optional) Network configuration for the AKS cluster. | <pre>object({<br/>    network_plugin = optional(string, "azure")<br/>    # network_plugin_mode: 'overlay' voor Azure CNI Overlay, null voor klassieke Azure CNI of BYO CNI.<br/>    # Wordt automatisch genegeerd bij BYO CNI (network_plugin = "none").<br/>    network_plugin_mode = optional(string, null)<br/>    # network_data_plane: 'azure' (default) of 'cilium' voor eBPF-gebaseerd dataplane.<br/>    # WAF - Security: Cilium biedt network policy enforcement op kernel-niveau via eBPF.<br/>    network_data_plane = optional(string, "azure")<br/>    # network_policy: wordt automatisch null bij BYO CNI (network_plugin = "none").<br/>    network_policy    = optional(string, "calico")<br/>    load_balancer_sku = optional(string, "standard")<br/>    ip_versions       = optional(list(string), ["IPv4"])<br/>    outbound_type     = optional(string, "loadBalancer")<br/>    dns_service_ip    = optional(string, null)<br/>    service_cidr      = optional(string, null)<br/>    # pod_cidr: verplicht bij Azure CNI Overlay of kubenet. Wordt genegeerd bij BYO CNI.<br/>    pod_cidr = optional(string, null)<br/>    # advanced_networking: alleen beschikbaar wanneer network_plugin = 'azure' en network_data_plane = 'cilium'.<br/>    # WAF - Security: schakel observability en security in voor diepgaand netwerk-inzicht.<br/>    advanced_networking = optional(object({<br/>      observability_enabled = optional(bool, false)<br/>      security_enabled      = optional(bool, false)<br/>    }), null)<br/>  })</pre> | <pre>{<br/>  "advanced_networking": null,<br/>  "dns_service_ip": null,<br/>  "ip_versions": [<br/>    "IPv4"<br/>  ],<br/>  "load_balancer_sku": "standard",<br/>  "network_data_plane": "azure",<br/>  "network_plugin": "azure",<br/>  "network_plugin_mode": null,<br/>  "network_policy": "calico",<br/>  "outbound_type": "loadBalancer",<br/>  "pod_cidr": null,<br/>  "service_cidr": null<br/>}</pre> | no |
| <a name="input_node_os_upgrade_channel"></a> [node\_os\_upgrade\_channel](#input\_node\_os\_upgrade\_channel) | (Optional) The upgrade channel for the nodes in the AKS cluster. Possible values are Unmanaged, SecurityPatch, NodeImage and None. Defaults to NodeImage. | `string` | `"NodeImage"` | no |
| <a name="input_node_resource_group"></a> [node\_resource\_group](#input\_node\_resource\_group) | (Optional) Name of the node resource group. Defaults to '{resource\_group\_name}-nodes'. | `string` | `null` | no |
| <a name="input_oidc_issuer_enabled"></a> [oidc\_issuer\_enabled](#input\_oidc\_issuer\_enabled) | (Optional) Enable OIDC issuer for the AKS cluster. | `bool` | `true` | no |
| <a name="input_oms_agent_enabled"></a> [oms\_agent\_enabled](#input\_oms\_agent\_enabled) | (Optional) Enable the OMS agent (Container Insights) for container log collection. Disable when using an alternative log collector such as Grafana Alloy. | `bool` | `true` | no |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | (Optional) Enable private cluster mode for the AKS cluster. | `bool` | `false` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | (Optional) ID of the private DNS zone to use for the AKS cluster. Required if private\_cluster\_enabled is true. | `string` | `null` | no |
| <a name="input_prometheus_enabled"></a> [prometheus\_enabled](#input\_prometheus\_enabled) | (Optional) Enable Azure Monitor managed Prometheus for metrics collection. Defaults to false. | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) Name of the resource group where resources will be created. | `string` | n/a | yes |
| <a name="input_role_based_access_control_enabled"></a> [role\_based\_access\_control\_enabled](#input\_role\_based\_access\_control\_enabled) | (Optional) Enable role-based access control (RBAC) for the AKS cluster. This is recommended for security compliance. | `bool` | `true` | no |
| <a name="input_skip_nodes_with_local_storage"></a> [skip\_nodes\_with\_local\_storage](#input\_skip\_nodes\_with\_local\_storage) | (Optional) If true, the cluster autoscaler will not remove nodes with local storage. Defaults to true. | `bool` | `true` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | (Optional) The SKU tier for the AKS cluster. Standard is recommended for production Haven clusters. | `string` | `"Standard"` | no |
| <a name="input_storage_profile"></a> [storage\_profile](#input\_storage\_profile) | (Optional) Storage profile configuration for the AKS cluster. | <pre>object({<br/>    blob_driver_enabled         = optional(bool, false)<br/>    disk_driver_enabled         = optional(bool, true)<br/>    file_driver_enabled         = optional(bool, true)<br/>    snapshot_controller_enabled = optional(bool, true)<br/>  })</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to all resources. | `map(string)` | <pre>{<br/>  "deployment_method": "terraform",<br/>  "module_name": "module-haven-cluster-azure-digilab"<br/>}</pre> | no |
| <a name="input_timeouts_update"></a> [timeouts\_update](#input\_timeouts\_update) | (Optional) Used when updating the Kubernetes Cluster. Defaults to 120 minutes (lager dan Azure DevOps pipeline timeout om state lock te voorkomen). | `string` | `"120m"` | no |
| <a name="input_virtual_network"></a> [virtual\_network](#input\_virtual\_network) | (Required) Virtual network configuration for the AKS cluster. If is\_existing is true, id must be provided. | <pre>object({<br/>    is_existing         = optional(bool, false)<br/>    id                  = optional(string)<br/>    name                = string<br/>    resource_group_name = string<br/>    address_space       = optional(list(string), [])<br/>    peerings            = optional(list(string), [])<br/>    subnet = optional(object({<br/>      is_existing       = optional(bool, false)<br/>      name              = string<br/>      address_prefixes  = optional(list(string), [])<br/>      service_endpoints = optional(list(string), ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"])<br/>    }))<br/>  })</pre> | n/a | yes |
| <a name="input_workload_autoscaler_profile"></a> [workload\_autoscaler\_profile](#input\_workload\_autoscaler\_profile) | (Optional) Workload autoscaler profile for the AKS cluster. | <pre>object({<br/>    keda_enabled                    = optional(bool, false)<br/>    vertical_pod_autoscaler_enabled = optional(bool, false)<br/>  })</pre> | `null` | no |
| <a name="input_workload_identity_enabled"></a> [workload\_identity\_enabled](#input\_workload\_identity\_enabled) | (Optional) Enable workload identity for the AKS cluster. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aks_system_managed_identity"></a> [aks\_system\_managed\_identity](#output\_aks\_system\_managed\_identity) | The principal ID of the AKS cluster managed identity. |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the AKS cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | n/a |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | The kube config of the AKS cluster. |
| <a name="output_kubeconfig_raw"></a> [kubeconfig\_raw](#output\_kubeconfig\_raw) | Raw kubeconfig for the AKS cluster |
| <a name="output_kubelet_identity"></a> [kubelet\_identity](#output\_kubelet\_identity) | The kubelet identity of the AKS cluster used for pulling container images |
| <a name="output_kubernetes_cluster_resourcegroup_name"></a> [kubernetes\_cluster\_resourcegroup\_name](#output\_kubernetes\_cluster\_resourcegroup\_name) | The resource group name of the AKS cluster. |
| <a name="output_load_balancer_ips"></a> [load\_balancer\_ips](#output\_load\_balancer\_ips) | n/a |
| <a name="output_node_resource_group_name"></a> [node\_resource\_group\_name](#output\_node\_resource\_group\_name) | The node resource group name of the AKS cluster. |
| <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id) | The resource ID of the AKS cluster. |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | n/a |
<!-- END_TF_DOCS -->

## Container Insights: ContainerLogV2 migration

This module is `azurerm`-only and does not configure a `kubernetes` provider or manage any
in-cluster resources. When `oms_agent_enabled = true` (the default), AKS Container Insights
writes logs to the legacy `ContainerLog` table, which
[Microsoft retires on 30 September 2026](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-logs-schema).

Consumers must apply the `container-azm-ms-agentconfig` ConfigMap themselves at root level to
switch to `ContainerLogV2`, gated on the same `oms_agent_enabled` value passed to the module:

```hcl
provider "kubernetes" {
  host                   = module.haven.kube_config.host
  cluster_ca_certificate = base64decode(module.haven.kube_config.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["get-token", "--environment", "AzurePublicCloud", "--server-id", data.azuread_service_principal.aks.client_id, "--login", "azurecli"]
    command     = "kubelogin"
  }
}

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
```

See [examples/minimal/container-insights.tf](examples/minimal/container-insights.tf) for a full working example, including the `kubelogin`/`azurecli` exec-auth setup required when `local_account_disabled = true`.

## Examples

This module includes comprehensive examples to help you get started:

- **[minimal](examples/minimal/)**: A complete AKS cluster with all infrastructure created by the module
- **[existing-infrastructure](examples/existing-infrastructure/)**: AKS cluster using existing VNet, DNS, and
  Log Analytics workspace

See the [CONTRIBUTING.md](CONTRIBUTING.md) file for detailed usage instructions and best practices.

## Testing

This module includes a comprehensive integration test suite that validates both examples:

### Quick Test

```bash
# Test the minimal example
cd examples && ./integration-test.sh minimal

# Test the existing-infrastructure example
cd examples && ./integration-test.sh existing-infrastructure

# Test all examples
cd examples && ./integration-test.sh all
```

### Advanced Testing Options

```bash
# Dry run (no actual deployment)
DRY_RUN=true ./integration-test.sh all

# Skip infrastructure destruction (for debugging)
SKIP_DESTROY=true ./integration-test.sh minimal

# CI/CD mode (no colors, structured output)
CI_MODE=true ./integration-test.sh all
```

The integration test suite:

- Validates Terraform configuration and formatting
- Deploys the complete infrastructure
- Tests AKS cluster connectivity and basic operations
- Validates monitoring integration
- Tests DNS configuration (if applicable)
- Generates GitLab CI-compatible JUnit XML reports
- Automatically destroys infrastructure after testing

### Test Reports

After running tests, you'll find detailed reports in the `test-results/` directory:

- `integration-test-report.xml` - JUnit XML report for CI/CD integration
- `integration-test.log` - Detailed execution log
- `summary.txt` - Human-readable test summary
