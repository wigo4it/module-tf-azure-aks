variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the cluster"
  type        = string
}

variable "vnet_address_space" {
  description = "CIDR ranges for the virtual network"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "CIDR ranges for the AKS subnet"
  type        = list(string)
}

variable "pod_cidr" {
  description = "CIDR range for pods when using Cilium overlay mode. Must not overlap with the node subnet."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster"
  type        = string
}

variable "default_node_pool_vm_size" {
  description = "VM size for the default node pool"
  type        = string
}

variable "default_node_pool_node_count" {
  description = "Number of nodes in the default node pool (ignored if auto-scaling is enabled)"
  type        = number
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the default node pool"
  type        = bool
}

variable "min_node_count" {
  description = "Minimum number of nodes when auto-scaling is enabled"
  type        = number
}

variable "max_node_count" {
  description = "Maximum number of nodes when auto-scaling is enabled"
  type        = number
}

variable "cilium_observability_enabled" {
  description = "Enable Cilium advanced network observability (Hubble)"
  type        = bool
}

variable "cilium_security_enabled" {
  description = "Enable Cilium advanced network security features"
  type        = bool
}

variable "additional_node_pools" {
  description = "Additional node pools to create"
  type = map(object({
    vm_size                        = string
    node_count                     = optional(number, 1)
    zones                          = optional(list(string), ["1", "2", "3"])
    mode                           = optional(string, "User")
    max_pods                       = optional(number, 120)
    labels                         = optional(map(string), {})
    taints                         = optional(list(string), [])
    spot_node                      = optional(bool, false)
    cluster_auto_scaling_enabled   = optional(bool, false)
    cluster_auto_scaling_min_count = optional(number, null)
    cluster_auto_scaling_max_count = optional(number, null)
    node_public_ip_enabled         = optional(bool, false)
  }))
}

variable "loadbalancer_ips" {
  description = "Specific load balancer IP addresses to use (if any)"
  type        = list(string)
}

variable "private_cluster_enabled" {
  description = "Enable private cluster (API server not accessible from public internet)"
  type        = bool
}

variable "sku_tier" {
  description = "SKU tier for the AKS cluster (Free, Standard, Premium)"
  type        = string
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be one of: Free, Standard, Premium."
  }
}

variable "enable_keda" {
  description = "Enable KEDA (Kubernetes-based Event Driven Autoscaling)"
  type        = bool
}

variable "enable_vpa" {
  description = "Enable VPA (Vertical Pod Autoscaler)"
  type        = bool
}

variable "vnet_peerings" {
  description = "List of VNet resource IDs to peer with"
  type        = list(string)
}
