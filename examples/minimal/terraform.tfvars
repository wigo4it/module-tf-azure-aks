# Haven-compliant AKS cluster configuration
# These are the default values moved from variables.tf for better practice

# Basic cluster configuration
cluster_name = "haven-cluster"
domain_name  = "haven.example.com"
location     = "West Europe"

# Network configuration with reasonable defaults
vnet_address_space      = ["10.0.0.0/16"]
subnet_address_prefixes = ["10.0.1.0/24"]

# Kubernetes version with current stable default
kubernetes_version = "1.33.0"

# Node pool configuration with cost-effective defaults
default_node_pool_vm_size    = "Standard_B2ms"
default_node_pool_node_count = 2

# Auto-scaling enabled by default for better resource management
enable_auto_scaling = true
min_node_count      = 1
max_node_count      = 5

# Optional configurations with sensible defaults
additional_node_pools = {}
loadbalancer_ips      = []

# Security defaults - private cluster disabled for easier testing
private_cluster_enabled = false

# Haven recommends Standard SKU for production
sku_tier = "Standard"

# Workload autoscaler - disabled by default
enable_keda = false
enable_vpa  = false

# VNet peerings
vnet_peerings = []
