# =============================
# Azure Monitor Metric Alerts
# =============================

# Node CPU Usage Alert
resource "azurerm_monitor_metric_alert" "node_cpu" {
  count = var.monitoring_alerts.enabled ? 1 : 0

  name                = "${var.name}-node-cpu-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Alert when average node CPU usage exceeds ${var.monitoring_alerts.node_cpu_threshold}%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.monitoring_alerts.node_cpu_threshold
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Node Memory Usage Alert
resource "azurerm_monitor_metric_alert" "node_memory" {
  count = var.monitoring_alerts.enabled ? 1 : 0

  name                = "${var.name}-node-memory-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Alert when average node memory usage exceeds ${var.monitoring_alerts.node_memory_threshold}%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_memory_working_set_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.monitoring_alerts.node_memory_threshold
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Pod Restart Alert
resource "azurerm_monitor_metric_alert" "pod_restarts" {
  count = var.monitoring_alerts.enabled ? 1 : 0

  name                = "${var.name}-pod-restart-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Alert when pod restarts exceed ${var.monitoring_alerts.pod_restart_threshold} in 15 minutes"
  severity            = 3
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Insights.Container/pods"
    metric_name      = "podReadyPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 90 # Alert when less than 90% of pods are ready (indicates restarts)
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Disk Usage Alert
resource "azurerm_monitor_metric_alert" "disk_usage" {
  count = var.monitoring_alerts.enabled ? 1 : 0

  name                = "${var.name}-disk-usage-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Alert when node disk usage exceeds ${var.monitoring_alerts.disk_usage_threshold}%"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_disk_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.monitoring_alerts.disk_usage_threshold
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# Node Not Ready Alert
resource "azurerm_monitor_metric_alert" "node_not_ready" {
  count = var.monitoring_alerts.enabled ? 1 : 0

  name                = "${var.name}-node-not-ready-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Alert when any node is in NotReady state"
  severity            = 1 # Critical
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_node_status_condition"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1

    dimension {
      name     = "status"
      operator = "Include"
      values   = ["Ready"]
    }

    dimension {
      name     = "condition"
      operator = "Include"
      values   = ["true"]
    }
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}

# API Server Availability Alert
resource "azurerm_monitor_metric_alert" "api_server_availability" {
  count = var.monitoring_alerts.enabled ? 1 : 0

  name                = "${var.name}-api-server-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_kubernetes_cluster.default.id]
  description         = "Alert when API server availability drops below 99.9%"
  severity            = 1 # Critical
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "cluster_autoscaler_unschedulable_pods_count"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0 # Alert if there are unschedulable pods (capacity issue)
  }

  dynamic "action" {
    for_each = var.monitoring_alerts.action_group_ids
    content {
      action_group_id = action.value
    }
  }

  tags = var.tags
}
