# default

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.35 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.37.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_kubernetes_cluster.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.userpool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_log_analytics_workspace.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_monitor_diagnostic_setting.aks_audit_logs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | resource |
| [azurerm_public_ip.egress_ipv4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.ingress_ipv4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.aks_identity_network_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.aks_identity_private_dns_zone_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_subnet.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_user_assigned_identity.aks_identity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_subnet.existing](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_additional_node_pools"></a> [aks\_additional\_node\_pools](#input\_aks\_additional\_node\_pools) | (Optional) Map of additional node pools to create for the AKS cluster. | <pre>map(object({<br>    vm_size                        = string<br>    node_count                     = optional(number, 1)<br>    zones                          = optional(list(string), ["1", "3"])<br>    mode                           = optional(string, "System")<br>    max_pods                       = optional(number, 120)<br>    labels                         = optional(map(string), {})<br>    taints                         = optional(list(string), [])<br>    spot_node                      = optional(bool, false)<br>    spot_max_price                 = optional(number, null)<br>    eviction_policy                = optional(string, null)<br>    node_os                        = optional(string, null)<br>    os_disk_size_gb                = optional(number, null)<br>    os_disk_type                   = optional(string, null)<br>    cluster_auto_scaling_enabled   = optional(bool, false)<br>    cluster_auto_scaling_min_count = optional(number, null)<br>    cluster_auto_scaling_max_count = optional(number, null)<br>    node_public_ip_enabled         = optional(bool, false)<br>  }))</pre> | `{}` | no |
| <a name="input_aks_audit_categories"></a> [aks\_audit\_categories](#input\_aks\_audit\_categories) | (Optional) List of audit categories to enable for the AKS cluster. This is recommended for security compliance. | `list(string)` | <pre>[<br>  "kube-apiserver",<br>  "kube-audit",<br>  "kube-audit-admin",<br>  "kube-controller-manager",<br>  "kube-scheduler",<br>  "cluster-autoscaler",<br>  "guard",<br>  "csi-azuredisk-controller",<br>  "csi-azurefile-controller",<br>  "csi-snapshot-controller"<br>]</pre> | no |
| <a name="input_aks_authorized_ip_ranges"></a> [aks\_authorized\_ip\_ranges](#input\_aks\_authorized\_ip\_ranges) | (Optional) List of authorized IP ranges for API server access. For security compliance, specify your organization's IP ranges. | `list(string)` | <pre>[<br>  "10.0.0.0/8",<br>  "172.16.0.0/12",<br>  "192.168.0.0/16"<br>]</pre> | no |
| <a name="input_aks_azure_active_directory_role_based_access_control"></a> [aks\_azure\_active\_directory\_role\_based\_access\_control](#input\_aks\_azure\_active\_directory\_role\_based\_access\_control) | (Optional) Azure Active Directory integration for RBAC. Required when local\_account\_disabled is true. | <pre>object({<br>    admin_group_object_ids = list(string)<br>    azure_rbac_enabled     = bool<br>    tenant_id              = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_aks_default_node_pool"></a> [aks\_default\_node\_pool](#input\_aks\_default\_node\_pool) | (Required) Configuration for the default node pool in the AKS cluster. | <pre>object({<br>    name                           = optional(string, "default")<br>    vm_size                        = string<br>    node_count                     = optional(number, 1)<br>    zones                          = optional(list(string), ["1", "2", "3"])<br>    mode                           = optional(string, "System")<br>    max_pods                       = optional(number, 120)<br>    labels                         = optional(map(string), {})<br>    spot_node                      = optional(bool, false)<br>    spot_max_price                 = optional(number, null)<br>    eviction_policy                = optional(string, null)<br>    node_os                        = optional(string, null)<br>    os_disk_size_gb                = optional(number, null)<br>    os_disk_type                   = optional(string, null)<br>    cluster_auto_scaling_enabled   = optional(bool, false)<br>    cluster_auto_scaling_min_count = optional(number, null)<br>    cluster_auto_scaling_max_count = optional(number, null)<br>    node_public_ip_enabled         = optional(bool, false)<br>    only_critical_addons_enabled   = optional(bool, false)<br>    upgrade_settings = optional(object({<br>      drain_timeout_in_minutes = optional(number, 5)<br>      max_surge                = optional(string, "10%")<br>      }), {<br>      drain_timeout_in_minutes = 5<br>      max_surge                = "10%"<br>    })<br>  })</pre> | n/a | yes |
| <a name="input_automatic_upgrade_channel"></a> [automatic\_upgrade\_channel](#input\_automatic\_upgrade\_channel) | (Optional) The automatic upgrade channel for the AKS cluster. | `string` | `"patch"` | no |
| <a name="input_azure_policy_enabled"></a> [azure\_policy\_enabled](#input\_azure\_policy\_enabled) | (Optional) Should the Azure Policy Add-On be enabled? For more details please visit Understand Azure Policy for Azure Kubernetes Service. Defaults to true. | `bool` | `true` | no |
| <a name="input_disk_encryption_set_id"></a> [disk\_encryption\_set\_id](#input\_disk\_encryption\_set\_id) | (Optional) The ID of the Disk Encryption Set which should be used for the Nodes and Volumes. More information can be found in the documentation. | `string` | `null` | no |
| <a name="input_dns_prefix"></a> [dns\_prefix](#input\_dns\_prefix) | (Optional) The DNS prefix for the AKS cluster. This will be used to create the DNS records. | `string` | `null` | no |
| <a name="input_enable_audit_logs"></a> [enable\_audit\_logs](#input\_enable\_audit\_logs) | (Optional) Enable audit logs for security compliance. This is recommended for production clusters. | `bool` | `true` | no |
| <a name="input_existing_log_analytics_workspace_id"></a> [existing\_log\_analytics\_workspace\_id](#input\_existing\_log\_analytics\_workspace\_id) | (Optional) ID of existing Log Analytics workspace to use for AKS monitoring. If not provided, a new workspace will be created. | `string` | `null` | no |
| <a name="input_image_cleaner_enabled"></a> [image\_cleaner\_enabled](#input\_image\_cleaner\_enabled) | (Optional) Enable image cleaner to remove unused images from the AKS cluster. | `bool` | `true` | no |
| <a name="input_image_cleaner_interval_hours"></a> [image\_cleaner\_interval\_hours](#input\_image\_cleaner\_interval\_hours) | (Optional) Interval in hours for the image cleaner to run. | `number` | `48` | no |
| <a name="input_key_vault_secrets_provider"></a> [key\_vault\_secrets\_provider](#input\_key\_vault\_secrets\_provider) | (Optional) Key Vault Secrets Provider configuration for enhanced secret management. | <pre>object({<br>    secret_rotation_enabled  = optional(bool, true)<br>    secret_rotation_interval = optional(string, "2m")<br>  })</pre> | `null` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | (Required) The Kubernetes version to use for the AKS cluster. | `string` | n/a | yes |
| <a name="input_loadbalancer_ips"></a> [loadbalancer\_ips](#input\_loadbalancer\_ips) | (Optional) The loadbalancer IP address(es) of the public ingress controller. If not provided, an azurerm\_public\_ip will be created. | `list(string)` | `[]` | no |
| <a name="input_local_account_disabled"></a> [local\_account\_disabled](#input\_local\_account\_disabled) | (Optional) Disable local accounts for security compliance. This is recommended. | `bool` | `false` | no |
| <a name="input_location"></a> [location](#input\_location) | (Required) Azure region where resources will be created. | `string` | n/a | yes |
| <a name="input_microsoft_defender_enabled"></a> [microsoft\_defender\_enabled](#input\_microsoft\_defender\_enabled) | (Optional) Enable Microsoft Defender for Containers | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name of the AKS cluster. | `string` | n/a | yes |
| <a name="input_network_profile"></a> [network\_profile](#input\_network\_profile) | (Optional) Network configuration for the AKS cluster. Uses Haven-compliant defaults if not specified. | <pre>object({<br>    network_plugin    = optional(string, "azure")<br>    network_policy    = optional(string, "calico")<br>    load_balancer_sku = optional(string, "standard")<br>    ip_versions       = optional(list(string), ["IPv4"])<br>  })</pre> | <pre>{<br>  "ip_versions": [<br>    "IPv4"<br>  ],<br>  "load_balancer_sku": "standard",<br>  "network_plugin": "azure",<br>  "network_policy": "calico"<br>}</pre> | no |
| <a name="input_oidc_issuer_enabled"></a> [oidc\_issuer\_enabled](#input\_oidc\_issuer\_enabled) | (Optional) Enable OIDC issuer for the AKS cluster. | `bool` | `true` | no |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | (Optional) Enable private cluster mode for the AKS cluster. | `bool` | `false` | no |
| <a name="input_private_dns_zone_id"></a> [private\_dns\_zone\_id](#input\_private\_dns\_zone\_id) | (Optional) ID of the private DNS zone to use for the AKS cluster. Required if private\_cluster\_enabled is true. | `string` | `null` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | (Required) Name of the resource group where resources will be created. | `string` | n/a | yes |
| <a name="input_role_based_access_control_enabled"></a> [role\_based\_access\_control\_enabled](#input\_role\_based\_access\_control\_enabled) | (Optional) Enable role-based access control (RBAC) for the AKS cluster. This is recommended for security compliance. | `bool` | `true` | no |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | (Optional) The SKU tier for the AKS cluster. Standard is recommended for production Haven clusters. | `string` | `"Standard"` | no |
| <a name="input_storage_profile"></a> [storage\_profile](#input\_storage\_profile) | (Optional) Storage profile configuration for the AKS cluster. | <pre>object({<br>    blob_driver_enabled         = bool<br>    disk_driver_enabled         = bool<br>    file_driver_enabled         = bool<br>    snapshot_controller_enabled = bool<br>  })</pre> | <pre>{<br>  "blob_driver_enabled": false,<br>  "disk_driver_enabled": true,<br>  "file_driver_enabled": true,<br>  "snapshot_controller_enabled": true<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to all resources. | `map(string)` | <pre>{<br>  "deployment_method": "terraform",<br>  "module_name": "module-haven-cluster-azure-digilab"<br>}</pre> | no |
| <a name="input_virtual_network"></a> [virtual\_network](#input\_virtual\_network) | (Required) Virtual network configuration for the AKS cluster. If is\_existing is true, id must be provided. | <pre>object({<br>    is_existing         = optional(bool, false)<br>    id                  = optional(string)<br>    name                = string<br>    resource_group_name = string<br>    address_space       = optional(list(string), [])<br>    peerings            = optional(list(string), [])<br>    subnet = optional(object({<br>      is_existing       = optional(bool, false)<br>      name              = string<br>      address_prefixes  = optional(list(string), [])<br>      service_endpoints = optional(list(string), ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"])<br>    }))<br>  })</pre> | n/a | yes |
| <a name="input_workload_autoscaler_profile"></a> [workload\_autoscaler\_profile](#input\_workload\_autoscaler\_profile) | (Optional) Workload autoscaler profile for the AKS cluster. | <pre>object({<br>    keda_enabled                    = bool<br>    vertical_pod_autoscaler_enabled = bool<br>  })</pre> | <pre>{<br>  "keda_enabled": false,<br>  "vertical_pod_autoscaler_enabled": false<br>}</pre> | no |
| <a name="input_workload_identity_enabled"></a> [workload\_identity\_enabled](#input\_workload\_identity\_enabled) | (Optional) Enable workload identity for the AKS cluster. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the AKS cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | n/a |
| <a name="output_load_balancer_ips"></a> [load\_balancer\_ips](#output\_load\_balancer\_ips) | n/a |
| <a name="output_resource_group_location"></a> [resource\_group\_location](#output\_resource\_group\_location) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | n/a |
<!-- END_TF_DOCS -->
