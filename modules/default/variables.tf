# =============================
# Required Variables
# =============================
variable "aks_default_node_pool" {
  description = <<-EOT
    (Required) Configuration for the default node pool in the AKS cluster.
    
    VM Size Selection Guidelines:
    - ⚠️  DO NOT use B-series VMs (explicitly not recommended by Microsoft for AKS)
    - ✅ Use v6-series VMs for production (latest generation, best performance & security)
    - ✅ Use v5-series VMs as alternative (good performance, wide availability)
    - Minimum requirements: 2 vCPUs and 4 GB RAM for system node pools
    
    🔒 RECOMMENDED - Confidential Computing (v6 - Latest, 4th Gen AMD EPYC Genoa):
    - Standard_DC2ads_v6 (2 vCPUs, 8 GB RAM) - BEST CHOICE: Latest gen + built-in SEV-SNP encryption
    - Standard_DC4ads_v6 (4 vCPUs, 16 GB RAM) - Higher capacity with confidential computing
    - Standard_DC8ads_v6 (8 vCPUs, 32 GB RAM) - Production workloads with enhanced security
    
    General Purpose (v5 - Previous gen, widely available):
    - Standard_D2s_v5 (2 vCPUs, 8 GB RAM) - Cost-effective, no confidential computing
    - Standard_D4s_v5 (4 vCPUs, 16 GB RAM) - Better performance
    - Standard_E2s_v5 (2 vCPUs, 16 GB RAM) - Memory-optimized workloads
    
    For more information: https://learn.microsoft.com/azure/virtual-machines/dcadsv6-series
  EOT
  type = object({
    name                           = optional(string, "default")
    vm_size                        = string
    node_count                     = optional(number, 3)
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
      drain_timeout_in_minutes = number
      max_surge                = string
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
  description = <<-EOT
    (Optional) Map of additional node pools to create for the AKS cluster.
    
    VM Size Selection Guidelines:
    - ⚠️  DO NOT use B-series VMs (explicitly not recommended by Microsoft for AKS)
    - ✅ Use v6-series VMs for production (latest generation, best performance & security)
    - ✅ Use v5-series VMs as alternative (good performance, wide availability)
    
    Common scenarios:
    - Confidential workloads: Standard_DC2ads_v6, Standard_DC4ads_v6, Standard_DC8ads_v6
    - User workloads: Standard_D2s_v5 or Standard_D4s_v5
    - Memory-intensive: Standard_E4s_v5 or Standard_E8s_v5
    - GPU workloads: NC-series or ND-series
    - Spot instances: Any v5/v6-series with spot_node = true (70-90% cost savings)
  EOT
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
    upgrade_settings = optional(object({
      drain_timeout_in_minutes = number
      max_surge                = string
      }), {
      drain_timeout_in_minutes = 5
      max_surge                = "10%"
    })
  }))
  default = {}
}

variable "aks_authorized_ip_ranges" {
  description = "(Optional) List of authorized IP ranges for API server access. Only applies to public clusters (not supported on private clusters). For security compliance, explicitly specify only your organization's specific IP ranges. Empty by default to enforce explicit configuration."
  type        = list(string)
  default     = []
  validation {
    condition = length(var.aks_authorized_ip_ranges) == 0 || alltrue([
      for cidr in var.aks_authorized_ip_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "All IP ranges must be valid CIDR blocks."
  }
}

variable "aks_audit_categories" {
  description = "(Optional) List of audit categories to enable for the AKS cluster. This is recommended for security compliance."
  type        = list(string)
  default     = ["kube-apiserver", "kube-audit", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "guard", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]
}

variable "aks_azure_active_directory_role_based_access_control" {
  description = "(Optional) Azure Active Directory integration for RBAC. Required when local_account_disabled is true."
  type = object({
    admin_group_object_ids = list(string)
    azure_rbac_enabled     = bool
    tenant_id              = optional(string)
  })
  default = null
}

variable "azure_policy_enabled" {
  description = "(Optional) Enable Azure Policy Add-On to enforce organizational standards and security baselines (Pod Security Standards, CIS Benchmark). Recommended for production to ensure policy compliance at scale. Default: enabled."
  type        = bool
  default     = true
}

variable "disk_encryption_set_id" {
  description = "(Optional) The ID of the Disk Encryption Set which should be used for the Nodes and Volumes. More information can be found in the documentation."
  type        = string
  default     = null
}

variable "enable_audit_logs" {
  description = "(Optional) Enable comprehensive audit logging for cluster activity monitoring, security compliance, and forensic analysis. Captures API server, authentication, and control plane events. Default: enabled for production compliance."
  type        = bool
  default     = true
}

variable "key_vault_secrets_provider" {
  description = "(Optional) Key Vault Secrets Provider configuration for enhanced secret management."
  type = object({
    secret_rotation_enabled  = bool
    secret_rotation_interval = string
  })
  default = {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
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

variable "microsoft_defender_enabled" {
  description = "(Optional) Enable Microsoft Defender for Containers for advanced threat protection, vulnerability scanning, and runtime security. Highly recommended for production workloads. Default: enabled for Standard/Premium SKU."
  type        = bool
  default     = true
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
  description = "(Optional) Disable local accounts to enforce Azure AD authentication and ensure all cluster access is centrally managed and audited. Required for production security compliance. When enabled, Azure AD RBAC must be configured."
  type        = bool
  default     = true

  validation {
    condition = (
      var.local_account_disabled == false ||
      (var.local_account_disabled == true &&
        var.aks_azure_active_directory_role_based_access_control != null &&
        var.aks_azure_active_directory_role_based_access_control.azure_rbac_enabled == true &&
      length(var.aks_azure_active_directory_role_based_access_control.admin_group_object_ids) > 0)
    )
    error_message = "When 'local_account_disabled' is true, 'aks_azure_active_directory_role_based_access_control' must be configured with 'azure_rbac_enabled' set to true and valid 'admin_group_object_ids'."
  }
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
  description = "(Optional) Enable private cluster mode to ensure API server is only accessible via private network. Strongly recommended for production environments to minimize attack surface. When enabled, the API server gets a private IP address."
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "(Optional) ID of the private DNS zone to use for the AKS cluster private API server. If not provided for private clusters, Azure creates a system-managed private DNS zone. Provide a custom DNS zone for advanced networking scenarios or when integrating with existing DNS infrastructure."
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
