# Required variables
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the cluster"
  type        = string
}

# Network configuration
variable "vnet_address_space" {
  description = "CIDR ranges for the virtual network"
  type        = list(string)
}

variable "subnet_address_prefixes" {
  description = "CIDR ranges for the AKS subnet"
  type        = list(string)
}

# Kubernetes configuration
variable "kubernetes_version" {
  description = "Kubernetes version to use for the cluster"
  type        = string
}

# Node pool configuration
variable "default_node_pool_vm_size" {
  description = "VM size for the default node pool"
  type        = string
}

variable "default_node_pool_node_count" {
  description = "Number of nodes in the default node pool"
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

# Security configuration
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

# Network profile
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

# Pod Security Standards
variable "pod_security_policy" {
  description = "Pod Security Standards configuration via Azure Policy"
  type = object({
    enabled             = optional(bool, true)
    level               = optional(string, "baseline")
    effect              = optional(string, "deny")
    excluded_namespaces = optional(list(string), [])
  })
}
