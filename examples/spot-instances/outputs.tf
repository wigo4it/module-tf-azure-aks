output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks_cluster.cluster_id
}

output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks_cluster.cluster_name
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = module.aks_cluster.cluster_fqdn
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${module.aks_cluster.cluster_name}"
}

output "cost_savings_estimate" {
  description = "Estimated monthly cost savings with spot instances"
  value = {
    regular_cost_monthly = "$600 (3x D4s_v5 on-demand nodes @ $200/month/node)"
    spot_cost_monthly    = "$90 (3x D4s_v5 spot nodes @ avg $30/month/node)"
    savings_monthly      = "$510"
    savings_percent      = "85%"
    note                 = "Spot pricing varies based on availability and demand"
  }
}
