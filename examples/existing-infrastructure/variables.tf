# Location configuration
variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

# Cluster configuration
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "existing-infra-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster"
  type        = string
  default     = "1.33.0"
}

# Node pool configuration
variable "default_node_pool_vm_size" {
  description = "VM size for the default node pool"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "default_node_pool_node_count" {
  description = "Number of nodes in the default node pool (ignored if auto-scaling is enabled)"
  type        = number
  default     = 2
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the default node pool"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Minimum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes when auto-scaling is enabled"
  type        = number
  default     = 5
}

# Optional configurations
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

variable "loadbalancer_ips" {
  description = "Specific load balancer IP addresses to use (if any)"
  type        = list(string)
  default     = []
}

variable "private_cluster_enabled" {
  description = "Enable private cluster (API server not accessible from public internet)"
  type        = bool
  default     = false
}

variable "sku_tier" {
  description = "SKU tier for the AKS cluster (Free, Standard, Premium)"
  type        = string
  default     = "Free"
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be one of: Free, Standard, Premium."
  }
}

# Workload autoscaler configuration
variable "enable_keda" {
  description = "Enable KEDA (Kubernetes-based Event Driven Autoscaling)"
  type        = bool
  default     = false
}

variable "enable_vpa" {
  description = "Enable VPA (Vertical Pod Autoscaler)"
  type        = bool
  default     = false
}

variable "network_profile" {
  description = "Network configuration for the AKS cluster"
  type = object({
    network_plugin      = optional(string, "azure")
    network_plugin_mode = optional(string, "overlay")
    network_policy      = optional(string, "calico")
    load_balancer_sku   = optional(string, "standard")
    ip_versions         = optional(list(string), ["IPv4"])
    pod_cidr            = optional(string, "10.244.0.0/16")
    service_cidr        = optional(string, "10.0.0.0/16")
    dns_service_ip      = optional(string, "10.0.0.10")
  })
}

variable "pod_security_policy" {
  description = "Pod Security Standards configuration via Azure Policy"
  type = object({
    enabled             = optional(bool, true)
    level               = optional(string, "baseline")
    effect              = optional(string, "audit")
    excluded_namespaces = optional(list(string), [])
  })
}
