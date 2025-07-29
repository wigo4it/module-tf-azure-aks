output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.haven.cluster_name
}

output "resource_group_name" {
  description = "Name of the resource group containing the AKS cluster"
  value       = module.haven.resource_group_name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = module.haven.resource_group_location
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster (useful for workload identity)"
  value       = module.haven.cluster_oidc_issuer_url
}

output "load_balancer_ips" {
  description = "Load balancer IP addresses"
  value       = module.haven.load_balancer_ips
}

output "subnet_id" {
  description = "ID of the subnet created for the cluster"
  value       = module.haven.subnet_id
}
