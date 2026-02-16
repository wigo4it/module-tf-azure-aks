# Haven-compliant AKS cluster configuration
# These are the default values moved from variables.tf for better practice

# Basic cluster configuration
cluster_name = "haven-cluster"
location     = "West Europe"

# Network configuration with reasonable defaults
vnet_address_space      = ["10.0.0.0/16"]
subnet_address_prefixes = ["10.0.1.0/24"]

# Kubernetes version with current stable default
kubernetes_version = "1.33.0"

# Node pool configuration with production-ready v6-series VMs
# Microsoft explicitly recommends AGAINST B-series VMs for AKS
# Standard_DC2ads_v6: 2 vCPUs, 8 GB RAM, 4th Gen AMD EPYC (Genoa), built-in SEV-SNP confidential computing
# Alternative: Standard_D2s_v5 (3rd Gen, general purpose, no confidential computing)
default_node_pool_vm_size    = "Standard_DC2ads_v6"
default_node_pool_node_count = 3

# Auto-scaling enabled by default for better resource management
# Minimum 3 nodes for production HA (Well-Architected Framework)
enable_auto_scaling = true
min_node_count      = 3
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
