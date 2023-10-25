variable "name" {
  description = "The name of the AKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use."
  type        = string
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

variable "traefik_internal_loadbalancer_ip" {
  description = "The loadbalancer IP address of the internal Traefik ingress controller."
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
    taints                         = optional(list(string), [])
    node_os                        = optional(string, null)
    os_disk_size_gb                = optional(number, null)
    os_disk_type                   = optional(string, null)
    cluster_auto_scaling           = optional(bool, false)
    cluster_auto_scaling_min_count = optional(number, null)
    cluster_auto_scaling_max_count = optional(number, null)
    enable_node_public_ip          = optional(bool, false)
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
    node_os                        = optional(string, null)
    os_disk_size_gb                = optional(number, null)
    os_disk_type                   = optional(string, null)
    cluster_auto_scaling           = optional(bool, false)
    cluster_auto_scaling_min_count = optional(number, null)
    cluster_auto_scaling_max_count = optional(number, null)
    enable_node_public_ip          = optional(bool, false)
  }))

  default = {}
}
