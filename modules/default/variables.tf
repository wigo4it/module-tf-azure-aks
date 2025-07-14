variable "location" {
  description = "Azure region of the resources"
  default     = "westeurope"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group where resources will be created"
  type        = string
  default     = null
}


#############################################
# Networking Variables
#############################################
# Required variables
variable "virtual_network" {
  type = object({
    is_existing         = optional(bool, false)
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
}

# Optional variables
variable "existing_dns_zone_id" {
  description = "ID of existing DNS zone to use. If provided, domain_name will only be used for validation and no new DNS zone will be created."
  type        = string
  default     = null
}

variable "existing_dns_zone_resource_group_name" {
  description = "Resource group name of the existing DNS zone. Required when existing_dns_zone_id is provided."
  type        = string
  default     = null
}

# variable "existing_vnet_name" {
#   description = "Name of existing VNet to use. If provided, virtual_network name will be ignored and no new VNet will be created."
#   type        = string
#   default     = null
# }

# variable "existing_vnet_subnet_name" {
#   description = "Name of existing subnet to use. If provided, virtual_network subnet will be ignored and no new subnet will be created."
#   type        = string
#   default     = null
# }

# variable "existing_vnet_resource_group_name" {
#   description = "Resource group name of the existing VNet. Required when existing_vnet_id is provided."
#   type        = string
#   default     = null
# }

# variable "vnet_peerings" {
#   description = "List of virtual network IDs to peer to. Don't forget to add this network on the other side of the peering."
#   type        = list(string)
#   default     = []
# }


################################################
# Cluster Variables
################################################
# Required variables
variable "domain_name" {
  description = "The domain name for the cluster to use. A wildcard DNS record will be created for all subdomains."
  type        = string
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use."
  type        = string
}

variable "name" {
  description = "The name of the AKS cluster."
  type        = string
}

# Optional variables
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

variable "aks_authorized_ip_ranges" {
  type        = list(string)
  description = "List of authorized IP ranges for API server access. For security compliance, specify your organization's IP ranges"
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"] # Private network ranges - update for your organization

  validation {
    condition = length(var.aks_authorized_ip_ranges) == 0 || alltrue([
      for cidr in var.aks_authorized_ip_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks."
  }
}

variable "aks_default_node_pool" {
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

variable "automatic_upgrade_channel" {
  description = "The automatic upgrade channel for the AKS cluster."
  type        = string
  default     = "patch"
}

variable "create_dns_records" {
  description = "Whether to create DNS A records. Set to false if you want to manage DNS records separately."
  type        = bool
  default     = true
}

variable "dns_prefix" {
  description = "The DNS prefix for the AKS cluster. This will be used to create the DNS records."
  type        = string
  default     = null
}

variable "image_cleaner_enabled" {
  description = "Enable image cleaner to remove unused images from the AKS cluster"
  type        = bool
  default     = true
}

variable "image_cleaner_interval_hours" {
  description = "Interval in hours for the image cleaner to run"
  type        = number
  default     = 48
}

variable "internal_loadbalancer_ip" {
  description = "The loadbalancer IP address of the internal ingress controller."
  type        = string
  default     = ""
}

variable "loadbalancer_ips" {
  description = "The loadbalancer IP address(es) of the public ingress controller. If not provided, an azurerm_public_ip will be created."
  type        = list(string)
  default     = []
}

variable "network_profile" {
  description = "Network configuration for the AKS cluster. Uses Haven-compliant defaults if not specified."
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
  description = "Enable OIDC issuer for the AKS cluster"
  type        = bool
  default     = true
}

variable "private_cluster_enabled" {
  type    = bool
  default = false
}

variable "sku_tier" {
  description = "The SKU tier for the AKS cluster. Standard is recommended for production Haven clusters."
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "SKU tier must be one of: Free, Standard, Premium."
  }
}

variable "storage_profile" {
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

variable "workload_autoscaler_profile" {
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
  description = "Enable workload identity for the AKS cluster"
  type        = bool
  default     = true
}

variable "existing_log_analytics_workspace_id" {
  description = "ID of existing Log Analytics workspace to use for AKS monitoring. If not provided, a new workspace will be created."
  type        = string
  default     = null
}
