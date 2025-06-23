# Example: Minimal AKS cluster deployment using the Haven module
# This example demonstrates how to deploy a basic Azure Kubernetes Service (AKS) cluster
# with custom networking and DNS using the Haven Terraform module.

module "haven" {
  source = "../../modules/default"

  name        = "my-cluster"
  domain_name = "my.base.domain.com"

  vnet_address_space      = ["10.8.0.0/15"]
  subnet_address_prefixes = ["10.8.0.0/16"]

  kubernetes_version = "1.33.0"

  aks_default_node_pool = {
    vm_size = "Standard_B2ms" # VM size for the default node pool
  }
}
