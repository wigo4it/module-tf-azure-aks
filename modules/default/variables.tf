# =============================
# Required Variables
# =============================
variable "aks_default_node_pool" {
  description = "(Required) Configuration for the default node pool in the AKS cluster."
  type = object({
    name                           = optional(string, "default")
    vm_size                        = string
    node_count                     = optional(number, 1)
    zones                          = optional(list(string), ["1", "2", "3"])
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
    upgrade_settings = optional(object({
      drain_timeout_in_minutes = optional(number, 5)
      max_surge                = optional(string, "10%")
      }), {
      drain_timeout_in_minutes = 5
      max_surge                = "10%"
    })
  })
}

variable "kubernetes_version" {
  description = "(Required) The Kubernetes version to use for the AKS cluster."
  type        = string
}

variable "location" {
  description = "(Required) Azure region where resources will be created."
  type        = string
}

variable "name" {
  description = "(Required) The name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "(Required) Name of the resource group where resources will be created."
  type        = string
}

variable "virtual_network" {
  description = "(Required) Virtual network configuration for the AKS cluster. If is_existing is true, id must be provided."
  type = object({
    is_existing         = optional(bool, false)
    id                  = optional(string)
    name                = string
    resource_group_name = string
    address_space       = optional(list(string), [])
    peerings            = optional(list(string), [])
    subnet = optional(object({
      is_existing       = optional(bool, false)
      name              = string
      address_prefixes  = optional(list(string), [])
      service_endpoints = optional(list(string), ["Microsoft.Storage", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"])
    }))
  })
  validation {
    condition = (
      (try(var.virtual_network.is_existing, false) == false) ||
      (try(var.virtual_network.is_existing, false) == true && try(var.virtual_network.id, "") != "")
    )
    error_message = "When 'virtual_network.is_existing' is true, 'virtual_network.id' must be provided."
  }
}

# =============================
# Optional Variables
# =============================
variable "aks_additional_node_pools" {
  description = "(Optional) Map of additional node pools to create for the AKS cluster."
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

variable "aks_authorized_ip_ranges" {
  description = "(Optional) List of authorized IP ranges for API server access. For security compliance, specify your organization's IP ranges."
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  validation {
    condition = length(var.aks_authorized_ip_ranges) == 0 || alltrue([
      for cidr in var.aks_authorized_ip_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks."
  }
}

variable "automatic_upgrade_channel" {
  description = "(Optional) The automatic upgrade channel for the AKS cluster."
  type        = string
  default     = "patch"
}

variable "dns_prefix" {
  description = "(Optional) The DNS prefix for the AKS cluster. This will be used to create the DNS records."
  type        = string
  default     = null
}

variable "existing_log_analytics_workspace_id" {
  description = "(Optional) ID of existing Log Analytics workspace to use for AKS monitoring. If not provided, a new workspace will be created."
  type        = string
  default     = null
}

variable "image_cleaner_enabled" {
  description = "(Optional) Enable image cleaner to remove unused images from the AKS cluster."
  type        = bool
  default     = true
}

variable "image_cleaner_interval_hours" {
  description = "(Optional) Interval in hours for the image cleaner to run."
  type        = number
  default     = 48
}

variable "loadbalancer_ips" {
  description = "(Optional) The loadbalancer IP address(es) of the public ingress controller. If not provided, an azurerm_public_ip will be created."
  type        = list(string)
  default     = []
}

variable "local_account_disabled" {
  description = "(Optional) Disable local accounts for security compliance. This is recommended."
  type        = bool
  default     = true
}

variable "network_profile" {
  description = "(Optional) Network configuration for the AKS cluster. Uses Haven-compliant defaults if not specified."
  type = object({
    network_plugin    = optional(string, "azure")
    network_policy    = optional(string, "calico")
    load_balancer_sku = optional(string, "standard")
    ip_versions       = optional(list(string), ["IPv4"])
  })
  default = {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    ip_versions       = ["IPv4"]
  }
}

variable "oidc_issuer_enabled" {
  description = "(Optional) Enable OIDC issuer for the AKS cluster."
  type        = bool
  default     = true
}

variable "private_cluster_enabled" {
  description = "(Optional) Enable private cluster mode for the AKS cluster."
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "(Optional) ID of the private DNS zone to use for the AKS cluster. Required if private_cluster_enabled is true."
  type        = string
  default     = null
}

variable "role_based_access_control_enabled" {
  description = "(Optional) Enable role-based access control (RBAC) for the AKS cluster. This is recommended for security compliance."
  type        = bool
  default     = true
}

variable "sku_tier" {
  description = "(Optional) The SKU tier for the AKS cluster. Standard is recommended for production Haven clusters."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be one of: Free, Standard, Premium."
  }
}

variable "storage_profile" {
  description = "(Optional) Storage profile configuration for the AKS cluster."
  type = object({
    blob_driver_enabled         = bool
    disk_driver_enabled         = bool
    file_driver_enabled         = bool
    snapshot_controller_enabled = bool
  })
  default = {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }
}

variable "tags" {
  description = "(Optional) A map of tags to assign to all resources."
  type        = map(string)
  default = {
    deployment_method = "terraform"
    module_name       = "module-haven-cluster-azure-digilab"
  }
}

variable "workload_autoscaler_profile" {
  description = "(Optional) Workload autoscaler profile for the AKS cluster."
  type = object({
    keda_enabled                    = bool
    vertical_pod_autoscaler_enabled = bool
  })
  default = {
    keda_enabled                    = false
    vertical_pod_autoscaler_enabled = false
  }
}

variable "workload_identity_enabled" {
  description = "(Optional) Enable workload identity for the AKS cluster."
  type        = bool
  default     = true
}
