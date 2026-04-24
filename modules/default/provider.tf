# Module-niveau: geen required_version — versie-constraints horen thuis in products/subscriptions.
# Zie: https://developer.hashicorp.com/terraform/language/modules/develop/providers
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}
