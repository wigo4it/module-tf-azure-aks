# Optimized variables with Haven-compliant defaults moved to terraform.tfvars

# Required variables
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "domain_name" {
  description = "Domain name for the cluster (a DNS zone will be created)"
  type        = string
}

# Location with European default
variable "location" {
  description = "Azure region for the cluster"
  type        = string
}

# Network configuration with reasonable defaults
variable "vnet_address_space" {
  description = "CIDR ranges for the virtual network"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "CIDR ranges for the AKS subnet"
  type        = list(string)
}

# Kubernetes version with current stable default
variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster"
  type        = string
}

# Node pool configuration with cost-effective defaults
variable "default_node_pool_vm_size" {
  description = "VM size for the default node pool"
  type        = string
}

variable "default_node_pool_node_count" {
  description = "Number of nodes in the default node pool (ignored if auto-scaling is enabled)"
  type        = number
}

# Auto-scaling enabled by default for better resource management
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

# Optional configurations with sensible defaults
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

# Security defaults - private cluster disabled for easier testing
variable "private_cluster_enabled" {
  description = "Enable private cluster (API server not accessible from public internet)"
  type        = bool
}

# Haven recommends Standard SKU for production
variable "sku_tier" {
  description = "SKU tier for the AKS cluster (Free, Standard, Premium)"
  type        = string
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be one of: Free, Standard, Premium."
  }
}

# Workload autoscaler - disabled by default
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
