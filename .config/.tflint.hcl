config {
  # Enable all rules by default
  disabled_by_default = false

  # Set minimum failure severity
  force = false

  # Call all modules during linting
  call_module_type = "all"
}

# Terraform module rules
plugin "terraform" {
  enabled = true
  version = "0.12.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

# Azure provider rules - disabled due to compatibility issues
# plugin "azurerm" {
#   enabled = true
#   version = "0.28.0"
#   source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
# }

# General rules
rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}
