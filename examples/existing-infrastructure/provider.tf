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
