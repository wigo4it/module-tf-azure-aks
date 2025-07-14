# Cluster configuration
cluster_name       = "haven-test"
kubernetes_version = "1.33.0"

# Node pool configuration
default_node_pool_vm_size    = "Standard_B2ms"
default_node_pool_node_count = 1
enable_auto_scaling          = true
min_node_count               = 1
max_node_count               = 3

# Test configuration
private_cluster_enabled = false
sku_tier                = "Free"
enable_keda             = false
enable_vpa              = false
create_dns_records      = true
