# Location configuration
variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "westeurope"
}

# # Variables for existing infrastructure
# variable "existing_vnet_name" {
#   description = "Name of the existing VNet to use"
#   type        = string
# }

# variable "existing_vnet_resource_group_name" {
#   description = "Resource group name where the existing VNet is located"
#   type        = string
# }

# variable "existing_subnet_name" {
#   description = "Name of the existing subnet to use for AKS nodes"
#   type        = string
# }

# variable "existing_dns_zone_name" {
#   description = "Name of the existing DNS zone to use"
#   type        = string
# }

# variable "existing_dns_zone_resource_group_name" {
#   description = "Resource group name where the existing DNS zone is located"
#   type        = string
# }

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

variable "internal_loadbalancer_ip" {
  description = "Internal load balancer IP address"
  type        = string
  default     = ""
}

variable "create_dns_records" {
  description = "Whether to create DNS A records in the existing DNS zone"
  type        = bool
  default     = true
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
