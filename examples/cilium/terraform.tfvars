# AKS cluster with Azure CNI powered by Cilium

# Basic cluster configuration
cluster_name = "haven-cilium"
location     = "West Europe"

# Network configuration
# pod_cidr must not overlap with vnet_address_space or subnet_address_prefixes
vnet_address_space      = ["10.0.0.0/16"]
subnet_address_prefixes = ["10.0.1.0/24"]
pod_cidr                = "192.168.0.0/16"

# Kubernetes version
kubernetes_version = "1.33.0"

# Node pool configuration
default_node_pool_vm_size    = "Standard_B2ms"
default_node_pool_node_count = 2

# Auto-scaling
enable_auto_scaling = true
min_node_count      = 1
max_node_count      = 5

# Cilium advanced networking features
cilium_observability_enabled = true
cilium_security_enabled      = true

# Optional configurations
additional_node_pools = {}
loadbalancer_ips      = []

# Security defaults
private_cluster_enabled = false

# SKU tier
sku_tier = "Standard"

# Workload autoscaler
enable_keda = false
enable_vpa  = false

# VNet peerings
vnet_peerings = []
