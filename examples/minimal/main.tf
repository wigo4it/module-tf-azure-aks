module "haven" {
  source = "git@gitlab.com:digilab.overheid.nl/platform/terraform-modules/azure-haven-k8s.git//modules/default"

  name        = "my-cluster"
  domain_name = "my.base.domain.com"

  vnet_address_space      = ["10.8.0.0/15"]
  subnet_address_prefixes = ["10.8.0.0/16"]

  kubernetes_version = "1.27.3"

  aks_default_node_pool = {
    vm_size = "Standard_B2ms"
  }
}
