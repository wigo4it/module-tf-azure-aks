# ==============================================================================
# Simplified Variables Following DRY, SRP, KISS Principles
# ==============================================================================
# This example only exposes variables for configuration that:
# 1. MUST be specified for the example to work (cluster_name, location)
# 2. Users commonly change (kubernetes_version, node_pool_config)
#
# All other settings (network_profile, pod_security_policy, microsoft_defender,
# sku_tier, etc.) use the module's WAF-compliant defaults.
# ==============================================================================

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

# Node pool configuration (KISS: simplified to single object)
variable "node_pool_config" {
  description = <<-EOT
    Node pool configuration. Uses WAF-compliant defaults from the module:
    - VM Size: Standard_D2ads_v6 (AMD EPYC, general purpose, widely available)
    - Auto-scaling: 3-5 nodes
    - Zones: 1, 2, 3 (enforced for HA)
    
    Override only if you need different settings.
  EOT
  type = object({
    vm_size                        = optional(string, "Standard_D2ads_v6")
    node_count                     = optional(number, 3)
    cluster_auto_scaling_enabled   = optional(bool, true)
    cluster_auto_scaling_min_count = optional(number, 3)
    cluster_auto_scaling_max_count = optional(number, 5)
  })
  default = {}

  validation {
    condition     = !can(regex("^Standard_B", var.node_pool_config.vm_size))
    error_message = "B-series VMs are not recommended by Microsoft for AKS. Use v5 or v6 series."
  }
}

# Existing infrastructure: Log Analytics workspace
variable "existing_log_analytics_workspace_id" {
  description = "ID of existing Log Analytics workspace for monitoring"
  type        = string
}
variable "container_registry_id" {
  description = "The ID of an existing Azure Container Registry to attach to the AKS cluster."
  type        = string
  default     = null
}

variable "disk_encryption_set_id" {
  description = "The ID of the Disk Encryption Set for CMK encryption."
  type        = string
  default     = null
}

variable "monitoring_action_group_id" {
  description = "The ID of the action group for monitoring alerts."
  type        = string
  default     = null
}

variable "enable_monitoring_alerts" {
  description = "Enable monitoring alerts for the AKS cluster."
  type        = bool
  default     = true
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default = {
    Environment = "test"
    ManagedBy   = "terraform"
    CostCenter  = "platform-engineering"
    Owner       = "platform-team"
    Project     = "aks-haven"
    Compliance  = "waf-compliant"
  }
}