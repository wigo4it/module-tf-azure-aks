# =============================
# AKS Cluster with Monitoring Alerts
# =============================

# Action Group for Alert Notifications
resource "azurerm_monitor_action_group" "ops_team" {
  name                = "aks-ops-team"
  resource_group_name = "rg-aks-monitoring"
  short_name          = "aks-ops"

  email_receiver {
    name                    = "ops-team-email"
    email_address           = "ops-team@company.com"
    use_common_alert_schema = true
  }

  sms_receiver {
    name         = "ops-oncall"
    country_code = "1"
    phone_number = "5555551234"
  }

  webhook_receiver {
    name                    = "teams-webhook"
    service_uri             = "https://outlook.office.com/webhook/YOUR-TEAMS-WEBHOOK-URL"
    use_common_alert_schema = true
  }
}

# AKS Cluster Module with Monitoring Alerts
module "aks_cluster" {
  source = "../../modules/default"

  name                = "prod-aks-cluster"
  location            = "westeurope"
  resource_group_name = "rg-aks-prod"
  kubernetes_version  = "1.29"

  # Default Node Pool - System workloads
  aks_default_node_pool = {
    name                           = "system"
    vm_size                        = "Standard_DC2ads_v6"
    node_count                     = 3
    zones                          = ["1", "2", "3"]
    mode                           = "System"
    max_pods                       = 250
    cluster_auto_scaling_enabled   = true
    cluster_auto_scaling_min_count = 3
    cluster_auto_scaling_max_count = 6
  }

  # Additional Node Pools - User workloads
  aks_additional_node_pools = {
    apps = {
      vm_size                        = "Standard_D4s_v5"
      node_count                     = 3
      mode                           = "User"
      zones                          = ["1", "2", "3"]
      max_pods                       = 250
      cluster_auto_scaling_enabled   = true
      cluster_auto_scaling_min_count = 2
      cluster_auto_scaling_max_count = 10
      labels = {
        workload = "applications"
      }
    }
  }

  # Virtual Network Configuration
  virtual_network = {
    is_existing         = false
    name                = "vnet-aks-prod"
    resource_group_name = "rg-aks-prod"
    address_space       = ["10.1.0.0/16"]
    subnet = {
      is_existing      = false
      name             = "snet-aks-nodes"
      address_prefixes = ["10.1.0.0/20"]
    }
  }

  # Network Profile - Azure CNI Overlay
  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "calico"
    load_balancer_sku   = "standard"
    pod_cidr            = "10.244.0.0/16"
    service_cidr        = "10.0.0.0/16"
    dns_service_ip      = "10.0.0.10"
  }

  # Security Configuration
  microsoft_defender_enabled = true
  private_cluster_enabled    = false # Set to true for production
  local_account_disabled     = true

  aks_azure_active_directory_role_based_access_control = {
    admin_group_object_ids = ["YOUR-AZURE-AD-GROUP-ID"]
    azure_rbac_enabled     = true
  }

  # Pod Security Standards
  pod_security_policy = {
    enabled             = true
    level               = "baseline"
    effect              = "deny" # Enforced mode
    excluded_namespaces = ["monitoring", "logging"]
  }

  # Monitoring Alerts Configuration
  monitoring_alerts = {
    enabled               = true
    action_group_ids      = [azurerm_monitor_action_group.ops_team.id]
    node_cpu_threshold    = 80
    node_memory_threshold = 85
    pod_restart_threshold = 5
    disk_usage_threshold  = 85
    api_server_latency_ms = 1000
  }

  # Operational Settings
  sku_tier                  = "Standard"
  automatic_upgrade_channel = "patch"

  workload_autoscaler_profile = {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }

  tags = {
    environment       = "production"
    cost_center       = "engineering"
    deployment_method = "terraform"
    monitoring        = "enabled"
  }
}

# Outputs
output "cluster_name" {
  value = module.aks_cluster.cluster_name
}

output "monitoring_status" {
  value = module.aks_cluster.monitoring_alerts_status
}

output "pod_security_status" {
  value = module.aks_cluster.pod_security_policy_status
}
