package test

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/stretchr/testify/assert"
)

// TestHavenAKSMinimalQuick runs a quick validation test for the minimal example
// This test only validates the terraform configuration and creates a plan
func TestHavenAKSMinimalQuick(t *testing.T) {
	t.Parallel()

	// Setup
	workingDir := filepath.Join("..", "examples", "minimal")

	// Load environment variables from .env file in the example folder
	envFile := filepath.Join(workingDir, ".env")
	if err := LoadEnvFromFile(envFile); err != nil {
		t.Logf("Warning: Could not load .env file from %s: %v", envFile, err)
	}

	// Generate unique names
	uniqueID := strings.ToLower(random.UniqueId())
	testName := fmt.Sprintf("haven-test-%s", uniqueID)

	// Create terraform options with environment variables loaded from .env file
	terraformOptions := &terraform.Options{
		TerraformDir: workingDir,
		Vars: map[string]interface{}{
			"cluster_name":                  testName,
			"location":                      "West Europe",
			"domain_name":                   fmt.Sprintf("%s.example.com", testName),
			"kubernetes_version":            "1.33.0",
			"vnet_address_space":            []string{"10.0.0.0/16"},
			"subnet_address_prefixes":       []string{"10.0.1.0/24"},
			"default_node_pool_vm_size":     "Standard_B2ms",
			"default_node_pool_node_count":  2,
			"enable_auto_scaling":           true,
			"min_node_count":                1,
			"max_node_count":                5,
			"additional_node_pools":         map[string]interface{}{},
			"loadbalancer_ips":              []string{},
			"private_cluster_enabled":       false,
			"sku_tier":                      "Standard",
			"enable_keda":                   false,
			"enable_vpa":                    false,
			"vnet_peerings":                 []string{},
		},
		EnvVars: loadEnvVars(),
		Logger:  logger.Default, // Enable logging to see errors
	}

	// Initialize terraform
	terraform.Init(t, terraformOptions)

	// Only plan - don't apply (exit code 2 means plan succeeded with changes)
	planExitCode := terraform.PlanExitCode(t, terraformOptions)
	assert.Contains(t, []int{0, 2}, planExitCode, "Terraform plan should succeed (0=no changes, 2=changes)")

	t.Log("Quick validation test passed for minimal example")
}

// TestHavenAKSExistingInfrastructureQuick runs a quick validation test for the existing-infrastructure example
func TestHavenAKSExistingInfrastructureQuick(t *testing.T) {
	t.Parallel()

	// Setup
	workingDir := filepath.Join("..", "examples", "existing-infrastructure")

	// Load environment variables from .env file in the example folder
	envFile := filepath.Join(workingDir, ".env")
	if err := LoadEnvFromFile(envFile); err != nil {
		t.Logf("Warning: Could not load .env file from %s: %v", envFile, err)
	}

	// Generate unique names
	uniqueID := strings.ToLower(random.UniqueId())
	testName := fmt.Sprintf("haven-test-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: workingDir,
		Vars: map[string]interface{}{
			"cluster_name":                  testName,
			"location":                      "West Europe",
			"kubernetes_version":            "1.33.0",
			"default_node_pool_vm_size":     "Standard_B2ms",
			"default_node_pool_node_count":  2,
			"enable_auto_scaling":           true,
			"min_node_count":                1,
			"max_node_count":                5,
			"additional_node_pools":         map[string]interface{}{},
			"loadbalancer_ips":              []string{},
			"internal_loadbalancer_ip":      "",
			"create_dns_records":            true,
			"private_cluster_enabled":       false,
			"sku_tier":                      "Standard",
			"enable_keda":                   false,
			"enable_vpa":                    false,
		},
		EnvVars: loadEnvVars(),
		Logger:  logger.Discard,
	}

	// Only validate and plan - don't apply
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, &terraform.Options{
		TerraformDir: terraformOptions.TerraformDir,
		Logger:       terraformOptions.Logger,
	})
	planExitCode := terraform.PlanExitCode(t, terraformOptions)
	assert.Contains(t, []int{0, 2}, planExitCode, "Terraform plan should succeed (0=no changes, 2=changes)")

	t.Log("Quick validation test passed for existing-infrastructure example")
}

// TestHavenAKSModuleValidation tests the module itself directly
func TestHavenAKSModuleValidation(t *testing.T) {
	t.Parallel()

	// Load environment variables from .env file (check multiple locations)
	envLocations := []string{
		filepath.Join("..", "examples", "minimal", ".env"),
		filepath.Join("..", ".env"),
		".env",
	}

	var envLoaded bool
	for _, envFile := range envLocations {
		if err := LoadEnvFromFile(envFile); err == nil {
			t.Logf("Loaded environment variables from %s", envFile)
			envLoaded = true
			break
		}
	}

	if !envLoaded {
		t.Logf("Warning: Could not load .env file from any location: %v", envLocations)
	}

	// Generate unique names
	uniqueID := strings.ToLower(random.UniqueId())
	testName := fmt.Sprintf("haven-test-%s", uniqueID)

	// Setup test configuration that uses the module directly
	workingDir := filepath.Join(os.TempDir(), fmt.Sprintf("terratest-haven-module-%s", uniqueID))
	defer os.RemoveAll(workingDir)

	// Create temporary directory
	os.MkdirAll(workingDir, 0755)

	// Get the absolute path to the module
	moduleDir, err := filepath.Abs(filepath.Join("..", "modules", "default"))
	assert.NoError(t, err)

	// Create a simple test configuration
	testConfig := fmt.Sprintf(`
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }
  }
}

provider "azurerm" {
  features {}
}

module "haven" {
  source = "%s"

  name        = "%s"
  domain_name = "%s.example.com"
  location    = "West Europe"

  virtual_network = {
    is_existing         = false
    name                = "vnet-%s"
    resource_group_name = "rg-%s"
    address_space       = ["10.0.0.0/16"]
    subnet = {
      name             = "subnet-%s"
      address_prefixes = ["10.0.1.0/24"]
    }
  }

  kubernetes_version = "1.33.0"

  aks_default_node_pool = {
    vm_size                        = "Standard_B2ms"
    node_count                     = 2
    cluster_auto_scaling_enabled   = true
    cluster_auto_scaling_min_count = 1
    cluster_auto_scaling_max_count = 5
  }
}

output "cluster_name" {
  value = module.haven.cluster_name
}

output "resource_group_name" {
  value = module.haven.resource_group_name
}
`, moduleDir, testName, testName, testName, testName, testName)

	// Write the configuration to a file
	configPath := filepath.Join(workingDir, "main.tf")
	err = os.WriteFile(configPath, []byte(testConfig), 0644)
	assert.NoError(t, err)

	terraformOptions := &terraform.Options{
		TerraformDir: workingDir,
		EnvVars:      loadEnvVars(),
		Logger:       logger.Discard,
	}

	// Validate the module configuration
	terraform.Init(t, terraformOptions)
	terraform.Validate(t, &terraform.Options{
		TerraformDir: terraformOptions.TerraformDir,
		Logger:       terraformOptions.Logger,
	})
	// Skip plan for this test since it requires Azure authentication
	// planExitCode := terraform.PlanExitCode(t, terraformOptions)
	// assert.Equal(t, 0, planExitCode, "Module terraform plan should succeed")

	t.Log("Module validation test passed")
}

// TestHavenAKSWithDifferentConfigurations tests various configuration combinations
func TestHavenAKSWithDifferentConfigurations(t *testing.T) {
	// Setup working directory
	workingDir := filepath.Join("..", "examples", "minimal")

	// Load environment variables from .env file in the minimal example folder
	envFile := filepath.Join(workingDir, ".env")
	if err := LoadEnvFromFile(envFile); err != nil {
		t.Logf("Warning: Could not load .env file from %s: %v", envFile, err)
	}

	testCases := []struct {
		name   string
		config map[string]interface{}
	}{
		{
			name: "minimal-config",
			config: map[string]interface{}{
				"kubernetes_version":            "1.33.0",
				"default_node_pool_vm_size":     "Standard_B2ms",
				"default_node_pool_node_count":  1,
				"enable_auto_scaling":           false,
				"min_node_count":                1,
				"max_node_count":                3,
				"sku_tier":                      "Free",
				"enable_keda":                   false,
				"enable_vpa":                    false,
			},
		},
		{
			name: "production-config",
			config: map[string]interface{}{
				"kubernetes_version":            "1.33.0",
				"default_node_pool_vm_size":     "Standard_D2s_v3",
				"default_node_pool_node_count":  3,
				"enable_auto_scaling":           true,
				"min_node_count":                2,
				"max_node_count":                10,
				"sku_tier":                      "Standard",
				"enable_keda":                   true,
				"enable_vpa":                    true,
			},
		},
	}

	for _, tc := range testCases {
		tc := tc // capture range variable
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			// Reload environment variables for each test case due to parallel execution
			if err := LoadEnvFromFile(envFile); err != nil {
				t.Logf("Warning: Could not load .env file from %s: %v", envFile, err)
			}

			// Generate unique names
			uniqueID := strings.ToLower(random.UniqueId())
			testName := fmt.Sprintf("hvn-%s-%s", tc.name[:3], uniqueID[:6])  // Shorter names to avoid storage account name limits

			// Merge base config with test case config
			vars := map[string]interface{}{
				"cluster_name":              testName,
				"location":                  "West Europe",
				"domain_name":               fmt.Sprintf("%s.example.com", testName),
				"vnet_address_space":        []string{"10.0.0.0/16"},
				"subnet_address_prefixes":   []string{"10.0.1.0/24"},
				"additional_node_pools":     map[string]interface{}{},
				"loadbalancer_ips":          []string{},
				"private_cluster_enabled":   false,
				"vnet_peerings":             []string{},
			}

			// Add test case specific configuration
			for key, value := range tc.config {
				vars[key] = value
			}

			terraformOptions := &terraform.Options{
				TerraformDir: workingDir,
				Vars:         vars,
				EnvVars:      loadEnvVars(),
				Logger:       logger.Discard,
			}

			// Only validate and plan
			terraform.Init(t, terraformOptions)
			terraform.Validate(t, &terraform.Options{
				TerraformDir: terraformOptions.TerraformDir,
				Logger:       terraformOptions.Logger,
			})
			planExitCode := terraform.PlanExitCode(t, terraformOptions)
			assert.Contains(t, []int{0, 2}, planExitCode, "Terraform plan should succeed for %s (0=no changes, 2=changes)", tc.name)

			t.Logf("Configuration test passed for %s", tc.name)
		})
	}
}

// Benchmark test to measure plan time
func BenchmarkHavenAKSPlan(b *testing.B) {
	// Setup working directory
	workingDir := filepath.Join("..", "examples", "minimal")

	// Load environment variables from .env file in the minimal example folder
	envFile := filepath.Join(workingDir, ".env")
	if err := LoadEnvFromFile(envFile); err != nil {
		b.Logf("Warning: Could not load .env file from %s: %v", envFile, err)
	}

	uniqueID := strings.ToLower(random.UniqueId())
	testName := fmt.Sprintf("haven-bench-%s", uniqueID)

	terraformOptions := &terraform.Options{
		TerraformDir: workingDir,
		Vars: map[string]interface{}{
			"cluster_name":                  testName,
			"location":                      "West Europe",
			"domain_name":                   fmt.Sprintf("%s.example.com", testName),
			"kubernetes_version":            "1.33.0",
			"vnet_address_space":            []string{"10.0.0.0/16"},
			"subnet_address_prefixes":       []string{"10.0.1.0/24"},
			"default_node_pool_vm_size":     "Standard_B2ms",
			"default_node_pool_node_count":  2,
			"enable_auto_scaling":           true,
			"min_node_count":                1,
			"max_node_count":                5,
			"additional_node_pools":         map[string]interface{}{},
			"loadbalancer_ips":              []string{},
			"private_cluster_enabled":       false,
			"sku_tier":                      "Standard",
			"enable_keda":                   false,
			"enable_vpa":                    false,
			"vnet_peerings":                 []string{},
		},
		EnvVars: loadEnvVars(),
		Logger:  logger.Discard,
	}

	// Initialize once
	terraform.Init(b, terraformOptions)

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		terraform.Plan(b, terraformOptions)
	}
}
