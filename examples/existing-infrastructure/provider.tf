terraform {
  required_version = "~> 1.14"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.80"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

# Authenticatie tegen het AKS data plane via kubelogin in 'azurecli'-modus, omdat
# local_account_disabled = true staat (geen client-cert/kube_admin_config beschikbaar).
provider "kubernetes" {
  host                   = module.haven.kube_config.host
  cluster_ca_certificate = base64decode(module.haven.kube_config.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args = [
      "get-token",
      "--environment", "AzurePublicCloud",
      "--server-id", data.azuread_service_principal.aks.client_id,
      "--login", "azurecli"
    ]
    command = "kubelogin"
  }
}
