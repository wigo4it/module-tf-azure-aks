variable "name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use."
  type        = string
}

variable "workload_autoscaler_profile" {
  type = object({
    keda_enabled                    = optional(bool, false)
    vertical_pod_autoscaler_enabled = optional(bool, false)
  })
}

variable "private_cluster_enabled" {
  type    = bool
  default = false
}

variable "sku_tier" {
  type    = string
  default = "Free"
}

variable "domain_name" {
  description = "The domain name for the cluster to use. A wildcard DNS record will be created for all subdomains."
  type        = string
}

variable "vnet_address_space" {
  description = "The CIDR ranges (address space) of the virtual network."
  type        = list(string)
}

variable "vnet_peerings" {
  description = "List of virtual network IDs to peer to. Don't forget to add this network on the other side of the peering."
  type        = list(string)
  default     = []
}

variable "subnet_address_prefixes" {
  description = "The address prefixes for the subnet. If not supplied, the entire `vnet_address_space` is used."
  type        = list(string)
}

variable "loadbalancer_ips" {
  description = "The loadbalancer IP address(es) of the public ingress controller. If not provided, an azurerm_public_ip will be created."
  type        = list(string)
  default     = []
}

variable "internal_loadbalancer_ip" {
  description = "The loadbalancer IP address of the internal ingress controller."
  type        = string
  default     = ""
}

variable "aks_authorized_ip_ranges" {
  type    = list(string)
  default = []
}

variable "aks_default_node_pool" {
  type = object({
    vm_size                        = string
    node_count                     = optional(number, 1)
    zones                          = optional(list(string), ["1", "3"])
    mode                           = optional(string, "System")
    max_pods                       = optional(number, 120)
    labels                         = optional(map(string), {})
    spot_node                      = optional(bool, false)
    spot_max_price                 = optional(number, null)
    eviction_policy                = optional(string, null)
    node_os                        = optional(string, null)
    os_disk_size_gb                = optional(number, null)
    os_disk_type                   = optional(string, null)
    cluster_auto_scaling_enabled   = optional(bool, false)
    cluster_auto_scaling_min_count = optional(number, null)
    cluster_auto_scaling_max_count = optional(number, null)
    node_public_ip_enabled         = optional(bool, false)
    only_critical_addons_enabled   = optional(bool, false)
  })
}

variable "aks_additional_node_pools" {
  description = "Map containing additional node pools"

  type = map(object({
    vm_size                        = string
    node_count                     = optional(number, 1)
    zones                          = optional(list(string), ["1", "3"])
    mode                           = optional(string, "System")
    max_pods                       = optional(number, 120)
    labels                         = optional(map(string), {})
    taints                         = optional(list(string), [])
    spot_node                      = optional(bool, false)
    spot_max_price                 = optional(number, null)
    eviction_policy                = optional(string, null)
    node_os                        = optional(string, null)
    os_disk_size_gb                = optional(number, null)
    os_disk_type                   = optional(string, null)
    cluster_auto_scaling_enabled   = optional(bool, false)
    cluster_auto_scaling_min_count = optional(number, null)
    cluster_auto_scaling_max_count = optional(number, null)
    node_public_ip_enabled         = optional(bool, false)
  }))

  default = {}
}

variable "storage_profile" {
  type = object({
    blob_driver_enabled = optional(bool, false)
    disk_driver_enabled = optional(bool, true)
    file_driver_enabled = optional(bool, true)
    snapshot_controller_enabled = optional(bool, true)
  })
}

variable "location" {
  description = "Azure region of the AKS cluster"
  default     = "westeurope"
  type        = string
}
