terraform {
  required_version = "~> 1.11" # Make sure that both Terraform and OpenTofu have this version 
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.58"
    }
  }
}
