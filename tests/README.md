# Terratest for Haven AKS Module

This directory contains [Terratest](https://terratest.gruntwork.io/) integration tests for the Haven AKS Terraform module.

## Overview

Terratest provides a Go-based testing framework for infrastructure code that offers several advantages over bash-based testing:

- **Type Safety**: Compile-time validation of test logic
- **Better Error Handling**: Structured Go error handling vs bash error handling
- **Parallel Testing**: Run multiple tests concurrently for faster feedback
- **Rich Assertions**: Built-in assertions for Azure resources, Kubernetes, etc.
- **Retry Logic**: Built-in retry mechanisms for flaky operations
- **Better Reporting**: Structured test output and reporting
- **Reusable Components**: Shared test utilities and helpers

## Test Structure

```text
tests/
├── go.mod                      # Go module definition
├── haven_aks_test.go          # Full integration tests (deploy & verify)
├── haven_aks_quick_test.go    # Quick validation tests (plan only)
├── test_helpers.go            # Shared test utilities and helpers
└── README.md                  # This file
```

## Test Types

### 1. Quick Tests (`*_quick_test.go`)

Fast validation tests that only validate and plan terraform configurations:

- `TestHavenAKSMinimalQuick` - Validates minimal example
- `TestHavenAKSExistingInfrastructureQuick` - Validates existing-infrastructure example
- `TestHavenAKSModuleValidation` - Tests module directly
- `TestHavenAKSWithDifferentConfigurations` - Tests various config combinations

### 2. Full Integration Tests (`*_test.go`)

Complete end-to-end tests that deploy actual infrastructure:

- `TestHavenAKSMinimal` - Full test of minimal example
- `TestHavenAKSExistingInfrastructure` - Full test of existing-infrastructure example

## Prerequisites & Installation

### 1. System Requirements

#### Go Installation

- **Go 1.23+** is required (current project uses Go 1.23.0)

**Install Go:**

```bash
# For Ubuntu/Debian
wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verify installation
go version
```

#### Terraform Installation

- **Terraform 1.5+** is required

**Install Terraform:**

```bash
# For Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Verify installation
terraform version
```

#### Azure CLI Installation

- **Azure CLI 2.0+** is required

**Install Azure CLI:**

```bash
# For Ubuntu/Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az version
```

### 2. Go Dependencies Installation

Navigate to the tests directory and install the required Go modules:

```bash
cd tests
go mod download
```

**Key Dependencies:**

- `github.com/gruntwork-io/terratest v0.50.0` - Main testing framework
- `github.com/stretchr/testify v1.10.0` - Assertion library
- `github.com/Azure/azure-sdk-for-go` - Azure SDK for Go

### 3. Azure Authentication Setup

You need an **Azure Service Principal** with appropriate permissions to create and manage Azure resources.

### Environment Variables

The tests automatically load environment variables from `.env` files in each example folder. This provides a
convenient way to set up Azure authentication credentials per example.

**Setup Steps:**

1. Create `.env` files in the example folders you want to test:

   ```bash
   # For minimal example
   cat > ../examples/minimal/.env << EOF
   ARM_TENANT_ID=your-tenant-id
   ARM_SUBSCRIPTION_ID=your-subscription-id
   EOF

   # For existing-infrastructure example
   cat > ../examples/existing-infrastructure/.env << EOF
   ARM_TENANT_ID=your-tenant-id
   ARM_SUBSCRIPTION_ID=your-subscription-id
   EOF
   ```

**Alternative Setup:**

Set the following environment variables for Azure authentication:

```bash
export ARM_TENANT_ID="your-tenant-id"
export ARM_SUBSCRIPTION_ID="your-subscription-id"
```

**Note:** The `.env` files are already included in `.gitignore` to prevent accidental commits of sensitive credentials.

For more detailed setup instructions, see [ENV_SETUP.md](ENV_SETUP.md).

## Running Tests

### Setup Verification

Before running tests, verify your setup:

```bash
# Check Go installation
go version

# Check Terraform installation
terraform version

# Check Azure CLI and authentication
az account show

# Navigate to tests directory
cd tests

# Verify Go dependencies
go mod verify
```

### Test Execution Overview

The test suite includes two types of tests:

1. **Quick Tests** - Fast validation (terraform validate + plan only)
2. **Integration Tests** - Full end-to-end tests (deploy + verify + cleanup)

### Quick Tests (Recommended for Development)

Quick tests are fast and safe - they only validate and plan configurations without deploying resources.

```bash
# Install dependencies first
go mod download

# Run ALL quick tests (recommended)
go test -v -timeout 15m -run "Quick|Validation|WithDifferentConfigurations"

# Run individual quick tests
go test -v -timeout 10m -run "TestHavenAKSMinimalQuick"
go test -v -timeout 10m -run "TestHavenAKSExistingInfrastructureQuick"
go test -v -timeout 5m -run "TestHavenAKSModuleValidation"
go test -v -timeout 15m -run "TestHavenAKSWithDifferentConfigurations"

# Run minimal and production config tests specifically
go test -v -timeout 15m -run "TestHavenAKSWithDifferentConfigurations/minimal-config"
go test -v -timeout 15m -run "TestHavenAKSWithDifferentConfigurations/production-config"
```

### Integration Tests (Deploys Real Infrastructure)

⚠️ **WARNING**: These tests deploy actual Azure resources and incur costs.

```bash
# Run ALL integration tests (deploys real infrastructure)
go test -v -timeout 90m

# Run individual integration tests
go test -v -timeout 60m -run "TestHavenAKSMinimal"
go test -v -timeout 75m -run "TestHavenAKSExistingInfrastructure"

# Run tests in parallel (faster but uses more resources)
go test -v -timeout 90m -parallel 2
```

### Test with Coverage

```bash
# Run with coverage report
go test -v -timeout 90m -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html

# Open coverage report in browser
open coverage.html  # macOS
xdg-open coverage.html  # Linux
```

### Debug Mode

To enable verbose terraform output, modify the test files to use `logger.Default` instead of `logger.Discard`:

```go
terraformOptions := &terraform.Options{
    // ...
    Logger: logger.Default, // Enable debug output
}
```

### Test-Specific Commands

#### Quick Validation Commands

```bash
# Test minimal example configuration
go test -v -run "TestHavenAKSMinimalQuick" -timeout 10m

# Test existing infrastructure example
go test -v -run "TestHavenAKSExistingInfrastructureQuick" -timeout 10m

# Test module validation directly
go test -v -run "TestHavenAKSModuleValidation" -timeout 5m

# Test different configuration combinations
go test -v -run "TestHavenAKSWithDifferentConfigurations" -timeout 15m
```

#### Integration Test Commands

```bash
# Full minimal example test (deploys resources)
go test -v -run "TestHavenAKSMinimal" -timeout 60m

# Full existing infrastructure test (deploys resources)
go test -v -run "TestHavenAKSExistingInfrastructure" -timeout 75m
```

### Useful Test Flags

```bash
# Run tests with verbose output
go test -v

# Set custom timeout
go test -v -timeout 30m

# Run tests in parallel
go test -v -parallel 3

# Run tests multiple times
go test -v -count 3

# Clear test cache
go clean -testcache && go test -v

# Run specific test patterns
go test -v -run "Quick"          # All quick tests
go test -v -run "Minimal"        # All minimal tests
go test -v -run "Existing"       # All existing infrastructure tests
```

## Test Stages

### Quick Tests

1. **Validation** - Validate terraform configuration syntax
2. **Planning** - Create and validate terraform plan

### Full Integration Tests

1. **Validation** - Validate terraform configuration syntax
2. **Planning** - Create and validate terraform plan
3. **Deployment** - Apply terraform configuration
4. **Verification** - Verify infrastructure is deployed correctly
5. **Connectivity** - Test AKS connectivity (if within authorized IP ranges)
6. **Workload** - Deploy and test sample workload
7. **DNS** - Verify DNS configuration
8. **Monitoring** - Verify monitoring integration
9. **Cleanup** - Destroy all created resources

## Test Configuration

### Authorized IP Ranges

The AKS cluster is configured with authorized IP ranges for security. Kubernetes connectivity tests will be
skipped if the test environment is not within the authorized ranges:

- `10.0.0.0/8` (Private networks)
- `172.16.0.0/12` (Private networks)
- `192.168.0.0/16` (Private networks)

### Resource Naming

Tests use unique identifiers to prevent resource conflicts:

- Format: `haven-test-{random-id}`
- Example: `haven-test-xyz123`

### Timeouts

- Quick tests: 10 minutes
- Full integration tests: 45-60 minutes
- Total test suite: 90 minutes

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Terratest

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  quick-tests:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4

    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3

    - name: Run Quick Tests
      run: |
        cd tests
        go test -v -timeout 10m -run "Quick"
      env:
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}

  integration-tests:
    runs-on: ubuntu-latest
    needs: quick-tests
    if: github.event_name == 'push'
    strategy:
      matrix:
        test: [TestHavenAKSMinimal, TestHavenAKSExistingInfrastructure]

    steps:
    - uses: actions/checkout@v4

    - name: Set up Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.21'

    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3

    - name: Run Integration Test
      run: |
        cd tests
        go test -v -timeout 60m -run "${{ matrix.test }}"
      env:
        ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
        ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
        ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
        ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
```

### GitLab CI Example

```yaml
stages:
  - validate
  - test

variables:
  GO_VERSION: "1.21"

quick-tests:
  stage: validate
  image: golang:${GO_VERSION}
  before_script:
    - apt-get update && apt-get install -y wget unzip
    - wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
    - unzip terraform_1.5.0_linux_amd64.zip -d /usr/local/bin/
  script:
    - cd tests
    - go mod download
    - go test -v -timeout 10m -run "Quick"

integration-tests:
  stage: test
  image: golang:${GO_VERSION}
  parallel:
    matrix:
      - TEST: TestHavenAKSMinimal
      - TEST: TestHavenAKSExistingInfrastructure
  before_script:
    - apt-get update && apt-get install -y wget unzip
    - wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
    - unzip terraform_1.5.0_linux_amd64.zip -d /usr/local/bin/
  script:
    - cd tests
    - go mod download
    - go test -v -timeout 60m -run "$TEST"
  rules:
    - if: '$CI_COMMIT_BRANCH == "main"'
    - when: manual
```

## Makefile Commands

Create a `Makefile` in the tests directory for easy command execution:

```makefile
.PHONY: test-quick test-full test-minimal test-existing test-all clean deps

# Install dependencies
deps:
 go mod download

# Run quick validation tests
test-quick:
 go test -v -timeout 10m -run "Quick"

# Run full integration tests
test-full:
 go test -v -timeout 90m

# Run minimal example test
test-minimal:
 go test -v -timeout 45m -run "TestHavenAKSMinimal"

# Run existing infrastructure test
test-existing:
 go test -v -timeout 60m -run "TestHavenAKSExistingInfrastructure"

# Run all tests
test-all: test-quick test-full

# Run tests with coverage
test-coverage:
 go test -v -timeout 90m -coverprofile=coverage.out
 go tool cover -html=coverage.out -o coverage.html

# Run benchmarks
test-bench:
 go test -v -bench=. -benchtime=3x

# Clean test cache
clean:
 go clean -testcache
 rm -f coverage.out coverage.html

# Run tests in parallel
test-parallel:
 go test -v -timeout 90m -parallel 2
```

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify Azure service principal credentials
   - Check subscription permissions
   - Ensure `az login` is successful

2. **Timeout Errors**
   - Increase test timeout values
   - Check Azure resource provisioning times
   - Verify network connectivity

3. **Resource Conflicts**
   - Tests use unique IDs to prevent conflicts
   - Clean up any orphaned resources manually
   - Check Azure subscription limits

4. **Kubernetes Connectivity**
   - Tests skip K8s connectivity if outside authorized IP ranges
   - This is expected behavior for security
   - Run from within authorized networks for full testing

### Debug Mode

Enable debug logging by changing `logger.Discard` to `logger.Default` in test files:

```go
terraformOptions := &terraform.Options{
    // ...
    Logger: logger.Default, // Enable debug output
}
```

### Resource Cleanup

Tests automatically clean up resources, but if tests are interrupted:

```bash
# List resources by tag
az resource list --tag "terratest=true" --output table

# Clean up manually if needed
az group delete --name "rg-haven-test-xyz123" --yes --no-wait
```

## Migration from Bash Tests

The Terratest implementation provides equivalent functionality to the bash-based integration tests with improved
reliability and maintainability. Both approaches can coexist during migration:

1. **Phase 1**: Add Terratest alongside existing bash tests
2. **Phase 2**: Migrate one test scenario at a time
3. **Phase 3**: Remove bash tests once Terratest is proven

Key advantages over bash tests:

- Better error handling and reporting
- Parallel execution capabilities
- Type safety and compile-time validation
- Rich assertions for Azure and Kubernetes resources
- Integrated retry logic for flaky operations
- Better CI/CD integration and reporting
