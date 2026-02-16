variable "admin_group_object_ids" {
  description = "Azure AD group object IDs for AKS cluster administrators"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "spot-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-aks-spot-instances"
}

variable "tags" {
  description = "Tags to assign to all resources"
  type        = map(string)
  default = {
    deployment_method = "terraform"
    example           = "spot-instances"
    cost_optimization = "enabled"
  }
}
