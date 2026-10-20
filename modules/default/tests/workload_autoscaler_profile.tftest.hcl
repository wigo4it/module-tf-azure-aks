mock_provider "azurerm" {}

variables {
  name                = "aks-autoscaler-test"
  location            = "westeurope"
  resource_group_name = "rg-autoscaler-test"
  kubernetes_version  = "1.36.3"

  aks_default_node_pool = {
    vm_size                        = "Standard_D4s_v5"
    cluster_auto_scaling_enabled   = true
    cluster_auto_scaling_min_count = 1
    cluster_auto_scaling_max_count = 3
  }

  aks_azure_active_directory_role_based_access_control = {
    admin_group_object_ids = ["00000000-0000-0000-0000-000000000001"]
    azure_rbac_enabled     = true
  }

  virtual_network = {
    name                = "vnet-autoscaler-test"
    resource_group_name = "rg-autoscaler-test"
    address_space       = ["10.0.0.0/16"]
    subnet = {
      name             = "snet-aks"
      address_prefixes = ["10.0.0.0/24"]
    }
  }
}

run "default_profile_omitted" {
  command = plan

  assert {
    condition     = length(azurerm_kubernetes_cluster.default.workload_autoscaler_profile) == 0
    error_message = "Default input must omit the workload autoscaler profile."
  }

  assert {
    condition     = output.kubelet_identity == null
    error_message = "An absent kubelet identity must return null without failing the plan."
  }
}

run "null_profile_omitted" {
  command = plan

  variables {
    workload_autoscaler_profile = null
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.default.workload_autoscaler_profile) == 0
    error_message = "Null input must omit the workload autoscaler profile."
  }
}

run "empty_profile_omitted" {
  command = plan

  variables {
    workload_autoscaler_profile = {}
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.default.workload_autoscaler_profile) == 0
    error_message = "Empty input must omit the workload autoscaler profile."
  }
}

run "disabled_profile_omitted" {
  command = plan

  variables {
    workload_autoscaler_profile = {
      keda_enabled                    = false
      vertical_pod_autoscaler_enabled = false
    }
  }

  assert {
    condition     = length(azurerm_kubernetes_cluster.default.workload_autoscaler_profile) == 0
    error_message = "Both disabled autoscalers must omit the workload autoscaler profile."
  }
}

run "keda_enabled" {
  command = plan

  variables {
    workload_autoscaler_profile = {
      keda_enabled = true
    }
  }

  assert {
    condition = (
      azurerm_kubernetes_cluster.default.workload_autoscaler_profile[0].keda_enabled &&
      !azurerm_kubernetes_cluster.default.workload_autoscaler_profile[0].vertical_pod_autoscaler_enabled
    )
    error_message = "KEDA must remain enabled with VPA disabled by default."
  }
}

run "vpa_enabled" {
  command = plan

  variables {
    workload_autoscaler_profile = {
      vertical_pod_autoscaler_enabled = true
    }
  }

  assert {
    condition = (
      !azurerm_kubernetes_cluster.default.workload_autoscaler_profile[0].keda_enabled &&
      azurerm_kubernetes_cluster.default.workload_autoscaler_profile[0].vertical_pod_autoscaler_enabled
    )
    error_message = "VPA must remain enabled with KEDA disabled by default."
  }
}

run "both_autoscalers_enabled" {
  command = plan

  variables {
    workload_autoscaler_profile = {
      keda_enabled                    = true
      vertical_pod_autoscaler_enabled = true
    }
  }

  assert {
    condition = (
      azurerm_kubernetes_cluster.default.workload_autoscaler_profile[0].keda_enabled &&
      azurerm_kubernetes_cluster.default.workload_autoscaler_profile[0].vertical_pod_autoscaler_enabled
    )
    error_message = "Both autoscalers must remain enabled when requested."
  }
}