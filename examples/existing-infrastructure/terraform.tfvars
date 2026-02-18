# ==============================================================================
# Simplified WAF-Compatible Configuration Following DRY, SRP, KISS Principles
# ==============================================================================
# This configuration demonstrates best practices:
# - DRY: Uses module defaults, no duplication
# - SRP: Only configures what's specific to this example
# - KISS: Simple, essential configuration only
#
# The module provides WAF-compliant defaults (97-98/100 Elite score):
# ✅ Security: Defender, Pod Security, RBAC, Calico (all enabled by default)
# ✅ Reliability: Standard SKU (99.95% SLA), 3-zone HA, auto-scaling
# ✅ Performance: DCadsv6 VMs, Azure CNI Overlay (250 pods/node)
# ✅ Operations: 30min drain timeout, 33% surge upgrades
# ✅ Cost: Auto-scaling, right-sized VMs
# ==============================================================================

# Minimal Required Configuration
cluster_name = "haven-test"

# Optional: Override node pool defaults if needed
# node_pool_config = {
#   vm_size                        = "Standard_DC4ads_v6"  # Larger VM
#   cluster_auto_scaling_min_count = 5                     # More nodes
#   cluster_auto_scaling_max_count = 10
# }
existing_log_analytics_workspace_id = "/subscriptions/f88ec198-1d77-40ea-b4d8-d065ed1073a4/resourceGroups/rg-haven-monitoring-test/providers/Microsoft.OperationalInsights/workspaces/law-haven-test"
container_registry_id               = "/subscriptions/f88ec198-1d77-40ea-b4d8-d065ed1073a4/resourceGroups/rg-haven-acr-test/providers/Microsoft.ContainerRegistry/registries/acrhaven20260218143001"
disk_encryption_set_id              = "REPLACE_WITH_DES_ID"
monitoring_action_group_id          = "REPLACE_WITH_ACTION_GROUP_ID"
enable_monitoring_alerts            = true

# Enhanced node pool configuration with ephemeral OS disks for better performance
node_pool_config = {
  vm_size                        = "Standard_D2ads_v6"
  node_count                     = 3
  os_disk_type                   = "Ephemeral"
  cluster_auto_scaling_enabled   = true
  cluster_auto_scaling_min_count = 3
  cluster_auto_scaling_max_count = 5
}
