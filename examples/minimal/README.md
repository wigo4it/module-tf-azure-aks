# minimal-optimized

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.12 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 4.35 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.35.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_haven"></a> [haven](#module\_haven) | ../../modules/default | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_log_analytics_workspace.aks_monitoring](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_resource_group.monitoring](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_node_pools"></a> [additional\_node\_pools](#input\_additional\_node\_pools) | Additional node pools to create | <pre>map(object({<br>    vm_size                        = string<br>    node_count                     = optional(number, 1)<br>    zones                          = optional(list(string), ["1", "2", "3"])<br>    mode                           = optional(string, "User")<br>    max_pods                       = optional(number, 120)<br>    labels                         = optional(map(string), {})<br>    taints                         = optional(list(string), [])<br>    spot_node                      = optional(bool, false)<br>    cluster_auto_scaling_enabled   = optional(bool, false)<br>    cluster_auto_scaling_min_count = optional(number, null)<br>    cluster_auto_scaling_max_count = optional(number, null)<br>    node_public_ip_enabled         = optional(bool, false)<br>  }))</pre> | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the AKS cluster | `string` | n/a | yes |
| <a name="input_default_node_pool_node_count"></a> [default\_node\_pool\_node\_count](#input\_default\_node\_pool\_node\_count) | Number of nodes in the default node pool (ignored if auto-scaling is enabled) | `number` | n/a | yes |
| <a name="input_default_node_pool_vm_size"></a> [default\_node\_pool\_vm\_size](#input\_default\_node\_pool\_vm\_size) | VM size for the default node pool | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain name for the cluster (a DNS zone will be created) | `string` | n/a | yes |
| <a name="input_enable_auto_scaling"></a> [enable\_auto\_scaling](#input\_enable\_auto\_scaling) | Enable auto-scaling for the default node pool | `bool` | n/a | yes |
| <a name="input_enable_keda"></a> [enable\_keda](#input\_enable\_keda) | Enable KEDA (Kubernetes-based Event Driven Autoscaling) | `bool` | n/a | yes |
| <a name="input_enable_vpa"></a> [enable\_vpa](#input\_enable\_vpa) | Enable VPA (Vertical Pod Autoscaler) | `bool` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version to use for the cluster | `string` | n/a | yes |
| <a name="input_loadbalancer_ips"></a> [loadbalancer\_ips](#input\_loadbalancer\_ips) | Specific load balancer IP addresses to use (if any) | `list(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Azure region for the cluster | `string` | n/a | yes |
| <a name="input_max_node_count"></a> [max\_node\_count](#input\_max\_node\_count) | Maximum number of nodes when auto-scaling is enabled | `number` | n/a | yes |
| <a name="input_min_node_count"></a> [min\_node\_count](#input\_min\_node\_count) | Minimum number of nodes when auto-scaling is enabled | `number` | n/a | yes |
| <a name="input_private_cluster_enabled"></a> [private\_cluster\_enabled](#input\_private\_cluster\_enabled) | Enable private cluster (API server not accessible from public internet) | `bool` | n/a | yes |
| <a name="input_sku_tier"></a> [sku\_tier](#input\_sku\_tier) | SKU tier for the AKS cluster (Free, Standard, Premium) | `string` | n/a | yes |
| <a name="input_subnet_address_prefixes"></a> [subnet\_address\_prefixes](#input\_subnet\_address\_prefixes) | CIDR ranges for the AKS subnet | `list(string)` | n/a | yes |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | CIDR ranges for the virtual network | `list(string)` | n/a | yes |
| <a name="input_vnet_peerings"></a> [vnet\_peerings](#input\_vnet\_peerings) | List of VNet resource IDs to peer with | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cert_manager_managed_identity_client_id"></a> [cert\_manager\_managed\_identity\_client\_id](#output\_cert\_manager\_managed\_identity\_client\_id) | Client ID of the managed identity for cert-manager |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the AKS cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | OIDC issuer URL for the cluster (useful for workload identity) |
| <a name="output_cluster_storage_account_name"></a> [cluster\_storage\_account\_name](#output\_cluster\_storage\_account\_name) | Name of the storage account created for the cluster |
| <a name="output_dns_zone_name"></a> [dns\_zone\_name](#output\_dns\_zone\_name) | Name of the DNS zone created for the cluster |
| <a name="output_load_balancer_ips"></a> [load\_balancer\_ips](#output\_load\_balancer\_ips) | Load balancer IP addresses |
| <a name="output_resource_group_location"></a> [resource\_group\_location](#output\_resource\_group\_location) | Location of the resource group |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | Name of the resource group containing the AKS cluster |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | ID of the subnet created for the cluster |
<!-- END_TF_DOCS -->
