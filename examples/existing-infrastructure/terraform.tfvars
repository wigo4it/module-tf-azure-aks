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

# Network profile - Azure CNI Overlay (Microsoft recommended for most scenarios)
# Overlay mode uses a separate pod CIDR to prevent VNet IP exhaustion
# Supports up to 250 pods per node
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

# Pod Security Standards - WAF Security Pillar (CIS Benchmark 5.2)
# Enforces baseline pod security to prevent privilege escalation
pod_security_policy = {
  enabled             = true
  level               = "baseline" # baseline (recommended) or restricted (strict)
  effect              = "audit"    # audit (test first) or deny (production)
  excluded_namespaces = []         # Add custom namespaces to exclude if needed
}
