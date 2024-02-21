# Terraform module: Haven

This module sets up all needed to run a Haven-compliant Kubernetes cluster in Azure. It includes networking, DNS, AKS and Workload Identity configuration.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_dns_a_record.int_wildcard](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_a_record.wildcard](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_a_record) | resource |
| [azurerm_dns_zone.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dns_zone) | resource |
| [azurerm_federated_identity_credential.cert_manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/federated_identity_credential) | resource |
| [azurerm_kubernetes_cluster.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_kubernetes_cluster_node_pool.userpool](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) | resource |
| [azurerm_public_ip.egress_ipv4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_public_ip.ingress_ipv4](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip) | resource |
| [azurerm_resource_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.aks_network_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.cert_manager_dns_zone_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_storage_account.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_subnet.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_user_assigned_identity.cert_manager](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [azurerm_virtual_network_peering.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network_peering) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aks_additional_node_pools"></a> [aks\_additional\_node\_pools](#input\_aks\_additional\_node\_pools) | Map containing additional node pools | <pre>map(object({<br>    vm_size                        = string<br>    node_count                     = optional(number, 1)<br>    zones                          = optional(list(string), ["1", "3"])<br>    mode                           = optional(string, "System")<br>    max_pods                       = optional(number, 120)<br>    labels                         = optional(map(string), {})<br>    taints                         = optional(list(string), [])<br>    spot_node                      = optional(bool, false)<br>    spot_max_price                 = optional(number, null)<br>    eviction_policy                = optional(string, null)<br>    node_os                        = optional(string, null)<br>    os_disk_size_gb                = optional(number, null)<br>    os_disk_type                   = optional(string, null)<br>    cluster_auto_scaling           = optional(bool, false)<br>    cluster_auto_scaling_min_count = optional(number, null)<br>    cluster_auto_scaling_max_count = optional(number, null)<br>    enable_node_public_ip          = optional(bool, false)<br>  }))</pre> | `{}` | no |
| <a name="input_aks_authorized_ip_ranges"></a> [aks\_authorized\_ip\_ranges](#input\_aks\_authorized\_ip\_ranges) | n/a | `list(string)` | `[]` | no |
| <a name="input_aks_default_node_pool"></a> [aks\_default\_node\_pool](#input\_aks\_default\_node\_pool) | n/a | <pre>object({<br>    vm_size                        = string<br>    node_count                     = optional(number, 1)<br>    zones                          = optional(list(string), ["1", "3"])<br>    mode                           = optional(string, "System")<br>    max_pods                       = optional(number, 120)<br>    labels                         = optional(map(string), {})<br>    taints                         = optional(list(string), [])<br>    spot_node                      = optional(bool, false)<br>    spot_max_price                 = optional(number, null)<br>    eviction_policy                = optional(string, null)<br>    node_os                        = optional(string, null)<br>    os_disk_size_gb                = optional(number, null)<br>    os_disk_type                   = optional(string, null)<br>    cluster_auto_scaling           = optional(bool, false)<br>    cluster_auto_scaling_min_count = optional(number, null)<br>    cluster_auto_scaling_max_count = optional(number, null)<br>    enable_node_public_ip          = optional(bool, false)<br>  })</pre> | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The domain name for the cluster to use. A wildcard DNS record will be created for all subdomains. | `string` | n/a | yes |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | The Kubernetes version to use. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the AKS cluster. | `string` | n/a | yes |
| <a name="input_subnet_address_prefixes"></a> [subnet\_address\_prefixes](#input\_subnet\_address\_prefixes) | The address prefixes for the subnet. If not supplied, the entire `vnet_address_space` is used. | `list(string)` | `[]` | no |
| <a name="input_traefik_internal_loadbalancer_ip"></a> [traefik\_internal\_loadbalancer\_ip](#input\_traefik\_internal\_loadbalancer\_ip) | The loadbalancer IP address of the internal Traefik ingress controller. | `string` | `""` | no |
| <a name="input_vnet_address_space"></a> [vnet\_address\_space](#input\_vnet\_address\_space) | The CIDR ranges (address space) of the virtual network. | `list(string)` | n/a | yes |
| <a name="input_vnet_peerings"></a> [vnet\_peerings](#input\_vnet\_peerings) | List of virtual network IDs to peer to. Don't forget to add this network on the other side of the peering. | `list(string)` | `[]` | no |
| <a name="input_workload_autoscaler_profile"></a> [workload\_autoscaler\_profile](#input\_workload\_autoscaler\_profile) | n/a | <pre>object({<br>    keda_enabled                              = optional(bool, false)<br>    vertical_pod_autoscaler_enabled           = optional(bool, false)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | n/a |
| <a name="output_cluster_storage_account_name"></a> [cluster\_storage\_account\_name](#output\_cluster\_storage\_account\_name) | n/a |
| <a name="output_dns_zone_name"></a> [dns\_zone\_name](#output\_dns\_zone\_name) | n/a |
| <a name="output_load_balancer_ips"></a> [load\_balancer\_ips](#output\_load\_balancer\_ips) | n/a |
| <a name="output_resource_group_location"></a> [resource\_group\_location](#output\_resource\_group\_location) | n/a |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
