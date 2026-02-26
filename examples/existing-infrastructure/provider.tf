terraform {
  required_version = "~> 1.11"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.58"
    }
  }
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Provider for hub subscription to access existing DNS zone
provider "azurerm" {
  alias           = "hub"
  subscription_id = "bacfdef3-cc63-4576-a0f6-662c478186c4"
  features {}
}
