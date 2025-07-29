# Contributing to Haven AKS Terraform Module

Welcome to the Haven AKS Terraform module! This guide provides comprehensive information about the module
architecture, usage, and how to contribute effectively.

## Table of Contents

- [Module Overview](#module-overview)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Examples](#examples)
- [Development Setup](#development-setup)
- [Testing](#testing)
- [Contributing Guidelines](#contributing-guidelines)
- [Code Standards](#code-standards)

## Module Overview

The Haven AKS Terraform module is a production-ready, security-focused Azure Kubernetes Service (AKS) deployment
solution that follows Azure Well-Architected Framework principles and Haven security standards.

### Key Features

- **Security-First Design**: RBAC-enabled, private networking, API server access controls
- **Production Ready**: Auto-scaling, monitoring, logging, and disaster recovery capabilities
- **Flexible Networking**: Support for both new and existing VNet/subnet configurations
- **Comprehensive Monitoring**: Integrated Log Analytics workspace and Container Insights
- **DNS Management**: Automated DNS zone and record creation with cert-manager integration
- **Storage Integration**: Dedicated storage account for cluster operations
- **Workload Identity**: Support for Azure AD workload identity and OIDC

### Compliance & Standards

- Azure Well-Architected Framework alignment
- Haven security standards compliance
- DRY (Don't Repeat Yourself) principles
- Infrastructure as Code best practices
- Comprehensive linting and validation

## Architecture

### Module Structure

```text
modules/default/
├── cluster.tf              # AKS cluster configuration
├── networking.tf           # VNet, subnet, and networking setup
├── log-analytics.tf        # Monitoring and logging configuration
├── dns-zone.tf            # DNS zone and record management
├── cert-manager.tf        # Certificate management setup
├── storage.tf             # Storage account for cluster operations
├── ingress.tf             # Ingress controller configuration
├── egress.tf              # Egress traffic management
├── node-pools.tf          # Additional node pool definitions
├── resource-group.tf      # Resource group creation
├── outputs.tf             # Module outputs
├── variables.tf           # Input variables
└── provider.tf            # Provider configuration
```

### Resource Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Resource Group                           │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   AKS Cluster   │  │  Log Analytics  │  │   DNS Zone      │ │
│  │   - RBAC        │  │   Workspace     │  │   - A Records   │ │
│  │   - Monitoring  │  │   - Insights    │  │   - Wildcard    │ │
│  │   - Auto-scale  │  │   - Retention   │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │ Virtual Network │  │ Storage Account │  │ Managed Identity│ │
│  │   - Subnet      │  │   - Blob        │  │   - Cert Mgr    │ │
│  │   - Endpoints   │  │   - Security    │  │   - RBAC        │ │
│  │   - Peering     │  │                 │  │                 │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐                     │
│  │  Public IPs     │  │   Node Pools    │                     │
│  │   - Ingress     │  │   - Default     │                     │
│  │   - Egress      │  │   - Additional  │                     │
│  │   - Load Bal.   │  │   - Auto-scale  │                     │
│  └─────────────────┘  └─────────────────┘                     │
└─────────────────────────────────────────────────────────────────┘
```

## Getting Started

### Prerequisites

1. **Azure CLI** - Authenticated with appropriate permissions
2. **Terraform** - Version ~> 1.12
3. **Git** - For version control
4. **Pre-commit** - For code quality checks

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd module-haven-cluster-azure-digilab

# Install pre-commit hooks
pre-commit install

# Verify installation
pre-commit run --all-files
```

## Examples

The module includes two comprehensive examples demonstrating different use cases:

### 1. Minimal Example

**Location**: `examples/minimal/`

**Purpose**: Demonstrates the simplest possible AKS deployment with all resources created by the module.

**Features**:

- New VNet and subnet creation
- Module-managed Log Analytics workspace
- Default security settings
- Basic DNS configuration
- Standard node pool configuration

#### Quick Start

```bash
cd examples/minimal

# Review and customize variables
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Initialize and plan
terraform init
terraform plan

# Deploy
terraform apply
```bash

#### Using tf-plan.sh Script

```bash
cd examples
./tf-plan.sh minimal
```

### 2. Existing Infrastructure Example

**Location**: `examples/existing-infrastructure/`

**Purpose**: Shows how to deploy AKS into existing Azure infrastructure (VNet, subnets, DNS zones).

**Features**:

- Uses existing VNet and subnet
- Configurable Log Analytics workspace
- Advanced networking scenarios
- Custom DNS zone integration
- Production-like configuration

#### Quick Start

```bash
cd examples/existing-infrastructure

# Create test infrastructure first
terraform apply -target=azurerm_virtual_network.networking
terraform apply -target=azurerm_subnet.networking

# Review and customize variables
vim terraform.tfvars

# Initialize and plan
terraform init
terraform plan

# Deploy
terraform apply
```

#### Using tf-plan.sh Script

```bash
cd examples
./tf-plan.sh existing-infrastructure
```

### Example Configuration Options

#### Minimal Example Variables

```hcl
# Basic cluster configuration
cluster_name       = "my-aks-cluster"
location           = "westeurope"

# Node pool settings
default_node_pool_vm_size    = "Standard_B2ms"
default_node_pool_node_count = 2
enable_auto_scaling          = true
min_node_count               = 1
max_node_count               = 5

# Security settings
sku_tier                = "Standard"
private_cluster_enabled = false
```

#### Existing Infrastructure Variables

```hcl
# Use existing infrastructure
existing_vnet_name                = "my-existing-vnet"
existing_vnet_resource_group_name = "my-network-rg"
existing_log_analytics_workspace_id = "/subscriptions/.../workspaces/my-workspace"

# Networking configuration
virtual_network = {
  subnet = {
    name = "aks-subnet"
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
  }
}

# Advanced features
workload_autoscaler_profile = {
  keda_enabled                    = true
  vertical_pod_autoscaler_enabled = true
}
```

## Development Setup

### 1. Environment Setup

```bash
# Set up Azure authentication
az login
az account set --subscription "your-subscription-id"

# Create .env file for examples
cat > examples/minimal/.env << EOF
ARM_SUBSCRIPTION_ID="your-subscription-id"
ARM_TENANT_ID="your-tenant-id"
EOF
```

### 2. Development Tools

```bash
# Install development dependencies
pip install pre-commit
npm install -g markdownlint-cli

# Install Terraform tools
# tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# terraform-docs
curl -sSLo ./terraform-docs.tar.gz https://terraform-docs.io/dl/v0.16.0/terraform-docs-v0.16.0-$(uname)-amd64.tar.gz
tar -xzf terraform-docs.tar.gz
chmod +x terraform-docs
sudo mv terraform-docs /usr/local/bin/
```

### 3. Pre-commit Configuration

The project uses centralized configuration in `.config/`:

```text
.config/
├── .tflint.hcl          # Terraform linting rules
├── .markdownlint.json   # Markdown formatting rules
└── .yamllint.yml        # YAML validation rules
```

## Testing

The module includes comprehensive testing at multiple levels:

### 1. Automated Testing with Terratest

For comprehensive automated testing using Go-based Terratest framework:

📖 **See [tests/README.md](tests/README.md) for detailed instructions** on:

- Installing Go, Terraform, and Azure CLI requirements
- Running quick validation tests (terraform validate + plan)
- Running full integration tests (deploy + verify + cleanup)
- Setting up Azure authentication and environment variables
- CI/CD integration examples

**Quick Start:**

```bash
# Navigate to tests directory
cd tests

# Install Go dependencies
go mod download

# Run quick validation tests (safe, no resource deployment)
go test -v -timeout 15m -run "Quick|Validation|WithDifferentConfigurations"

# Run full integration tests (deploys real Azure resources)
go test -v -timeout 90m
```

### 2. Local Validation

```bash
# Format all Terraform files
terraform fmt -recursive

# Validate syntax
find . -name "*.tf" -exec dirname {} \; | sort -u | xargs -I {} terraform -chdir={} validate

# Run linting
tflint --config=.config/.tflint.hcl --recursive

# Run all pre-commit checks
pre-commit run --all-files
```

### 3. Plan Testing

```bash
# Test minimal example
cd examples
./tf-plan.sh minimal

# Test existing infrastructure example
./tf-plan.sh existing-infrastructure
```

### 4. Manual Integration Testing

```bash
# Deploy minimal example
cd examples/minimal
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Verify deployment
kubectl get nodes
kubectl get pods --all-namespaces

# Cleanup
terraform destroy
```

## Contributing Guidelines

### 1. Code Changes

1. **Fork the repository** and create a feature branch
2. **Make your changes** following coding standards
3. **Test thoroughly** using the provided examples
4. **Run pre-commit checks** to ensure quality
5. **Submit a pull request** with detailed description

### 2. Commit Message Format

```text
type(scope): brief description

Detailed explanation of the change, including:
- What was changed and why
- Any breaking changes
- References to issues or requirements
```

Example:

```text
feat(networking): add support for custom service endpoints

- Added variable for configuring subnet service endpoints
- Updated existing infrastructure example
- Maintains backward compatibility

Fixes #123
```

### 3. Pull Request Process

1. Ensure all tests pass
2. Update documentation as needed
3. Add/update examples if adding new features
4. Request review from maintainers
5. Address feedback promptly

### 4. Issue Reporting

When reporting issues, include:

- Terraform version
- Azure CLI version
- Full error messages
- Minimal reproduction case
- Expected vs actual behavior

## Code Standards

### 1. Terraform Best Practices

- **DRY Principles**: Avoid code duplication
- **Clear Naming**: Use descriptive resource names
- **Comments**: Document complex logic
- **Variables**: Provide descriptions and validation
- **Outputs**: Include useful information for consumers

### 2. Security Standards

- **RBAC**: Enable role-based access control
- **Network Security**: Use private endpoints and NSGs
- **Secrets Management**: Use Azure Key Vault integration
- **Monitoring**: Enable comprehensive logging
- **Compliance**: Follow Azure security baselines

### 3. File Organization

```terraform
# 1. Data sources
data "azurerm_resource_group" "example" { ... }

# 2. Locals
locals {
  common_tags = { ... }
}

# 3. Resources (grouped logically)
resource "azurerm_virtual_network" "main" { ... }
resource "azurerm_subnet" "aks" { ... }

# 4. Outputs
output "cluster_id" { ... }
```

### 4. Variable Validation

```terraform
variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 63
    error_message = "Cluster name must be between 1 and 63 characters."
  }
}
```

## Support

- **Documentation**: Check README.md and inline comments
- **Examples**: Review the provided examples
- **Issues**: Create GitHub issues for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

---

Thank you for contributing to the Haven AKS Terraform module! Your contributions help make Azure Kubernetes
deployments more secure, reliable, and maintainable.
