# Cluster configuration
cluster_name       = "haven-test"
kubernetes_version = "1.33.0"

# Node pool configuration with production-ready v6-series VMs
# Microsoft explicitly recommends AGAINST B-series VMs for AKS
# Standard_DC2ads_v6: 2 vCPUs, 8 GB RAM, 4th Gen AMD EPYC (Genoa), built-in SEV-SNP confidential computing
# Alternative: Standard_D2s_v5 (3rd Gen, general purpose, no confidential computing)
default_node_pool_vm_size    = "Standard_DC2ads_v6"
default_node_pool_node_count = 3
enable_auto_scaling          = true
min_node_count               = 3
max_node_count               = 5

# Test configuration
private_cluster_enabled = false
sku_tier                = "Free"
enable_keda             = false
enable_vpa              = false
