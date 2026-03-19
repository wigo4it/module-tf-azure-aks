output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.haven.cluster_name
}

output "resource_id" {
  description = "Resource ID of the AKS cluster"
  value       = module.haven.resource_id
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
  description = "ID of the subnet used by the cluster"
  value       = module.haven.subnet_id
}

output "kubelet_identity" {
  description = "Kubelet identity used for pulling container images"
  value       = module.haven.kubelet_identity
}
