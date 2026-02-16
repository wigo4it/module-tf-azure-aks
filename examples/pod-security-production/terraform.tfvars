# Pod Security Standards - Production Example Configuration
# This demonstrates enforcing baseline pod security with deny mode

# Basic cluster configuration
cluster_name = "pod-security-demo"
location     = "westeurope"

# Network configuration
vnet_address_space      = ["10.1.0.0/16"]
subnet_address_prefixes = ["10.1.1.0/24"]

# Kubernetes version
kubernetes_version = "1.33.0"

# Network profile - Azure CNI Overlay
network_profile = {
  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  network_policy      = "calico"
  load_balancer_sku   = "standard"
  ip_versions         = ["IPv4"]
  pod_cidr            = "10.244.0.0/16"
  service_cidr        = "10.0.0.0/16"
  dns_service_ip      = "10.0.0.10"
}

# Node pool configuration - Production-ready v6-series
default_node_pool_vm_size    = "Standard_DC2ads_v6"
default_node_pool_node_count = 3
enable_auto_scaling          = true
min_node_count               = 3
max_node_count               = 5

# Security configuration - Production settings
private_cluster_enabled = false # Set to true for production
sku_tier                = "Standard"

# 🔒 Pod Security Standards - PRODUCTION CONFIGURATION
# This blocks non-compliant pod deployments
pod_security_policy = {
  enabled = true
  level   = "baseline" # Baseline: Prevents known privilege escalations
  effect  = "deny"     # Deny: BLOCKS non-compliant deployments (recommended for production)

  # Optional: Exclude specific namespaces (use sparingly)
  # System namespaces (kube-system, gatekeeper-system, azure-arc) are automatically excluded
  excluded_namespaces = [
    # "monitoring",  # Uncomment if monitoring tools require privileged access
    # "logging",     # Uncomment if logging agents need host access
  ]
}

# 📊 Alternative Configurations:

# For TESTING (audit mode - logs violations but allows deployment):
# pod_security_policy = {
#   enabled = true
#   level   = "baseline"
#   effect  = "audit"
#   excluded_namespaces = []
# }

# For MAXIMUM SECURITY (restricted mode - strictest pod hardening):
# pod_security_policy = {
#   enabled = true
#   level   = "restricted"
#   effect  = "deny"
#   excluded_namespaces = []
# }

# For DEVELOPMENT (disabled - no policy enforcement):
# pod_security_policy = {
#   enabled = false
#   level   = "disabled"
#   effect  = "audit"
#   excluded_namespaces = []
# }
