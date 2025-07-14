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
	"github.com/stretchr/testify/require"
)

// Helper functions for common test operations

// CreateTestConfig creates a temporary terraform configuration for testing
func CreateTestConfig(t *testing.T, modulePath string, vars map[string]interface{}) *terraform.Options {
	uniqueID := strings.ToLower(random.UniqueId())
	workingDir := filepath.Join(os.TempDir(), fmt.Sprintf("terratest-haven-%s", uniqueID))

	// Create temporary directory
	err := os.MkdirAll(workingDir, 0755)
	require.NoError(t, err)

	// Cleanup on test completion
	t.Cleanup(func() {
		os.RemoveAll(workingDir)
	})

	// Build terraform configuration
	config := fmt.Sprintf(`
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "haven" {
  source = "%s"

`, modulePath)

	// Add variables to configuration
	for key, value := range vars {
		switch v := value.(type) {
		case string:
			config += fmt.Sprintf("  %s = \"%s\"\n", key, v)
		case bool:
			config += fmt.Sprintf("  %s = %t\n", key, v)
		case int:
			config += fmt.Sprintf("  %s = %d\n", key, v)
		case []string:
			config += fmt.Sprintf("  %s = %q\n", key, v)
		default:
			config += fmt.Sprintf("  %s = %v\n", key, v)
		}
	}

	config += `}

# Outputs for testing
output "cluster_name" {
  value = module.haven.cluster_name
}

output "resource_group_name" {
  value = module.haven.resource_group_name
}

output "resource_group_location" {
  value = module.haven.resource_group_location
}

output "dns_zone_name" {
  value = module.haven.dns_zone_name
}

output "log_analytics_workspace_id" {
  value = module.haven.log_analytics_workspace_id
}
`

	// Write configuration to file
	configPath := filepath.Join(workingDir, "main.tf")
	err = os.WriteFile(configPath, []byte(config), 0644)
	require.NoError(t, err)

	return &terraform.Options{
		TerraformDir: workingDir,
		EnvVars:      loadEnvVars(),
		Logger:       logger.Discard,
	}
}

// ValidateRequiredEnvVars checks that all required environment variables are set
func ValidateRequiredEnvVars(t *testing.T) {
	requiredVars := []string{
		"ARM_TENANT_ID",
		"ARM_SUBSCRIPTION_ID",
		"ARM_CLIENT_ID",
		"ARM_CLIENT_SECRET",
	}

	for _, envVar := range requiredVars {
		value := os.Getenv(envVar)
		require.NotEmpty(t, value, "Environment variable %s must be set", envVar)
	}
}

// GenerateTestName creates a unique test name with the given prefix
func GenerateTestName(prefix string) string {
	uniqueID := strings.ToLower(random.UniqueId())
	return fmt.Sprintf("%s-%s", prefix, uniqueID)
}

// StandardMinimalConfig returns a standard minimal configuration for testing
func StandardMinimalConfig(testName string) map[string]interface{} {
	return map[string]interface{}{
		"cluster_name":             testName,
		"location":                 "West Europe",
		"domain_name":              fmt.Sprintf("%s.example.com", testName),
		"kubernetes_version":       "1.33.0",
		"vnet_address_space":       []string{"10.0.0.0/16"},
		"subnet_address_prefixes":  []string{"10.0.1.0/24"},
		"default_node_pool_vm_size": "Standard_B2s",
		"sku_tier":                 "Free",
		"enable_auto_scaling":      false,
		"enable_keda":              false,
		"enable_vpa":               false,
	}
}

// StandardExistingInfraConfig returns a standard configuration for existing infrastructure testing
func StandardExistingInfraConfig(testName string, workspaceID, subnetName, vnetName, vnetRG, dnsZone, dnsRG string) map[string]interface{} {
	return map[string]interface{}{
		"cluster_name":                          testName,
		"location":                              "West Europe",
		"domain_name":                           dnsZone,
		"kubernetes_version":                    "1.33.0",
		"existing_log_analytics_workspace_id":  workspaceID,
		"existing_subnet_name":                  subnetName,
		"existing_vnet_name":                    vnetName,
		"existing_vnet_resource_group_name":     vnetRG,
		"existing_dns_zone_name":                dnsZone,
		"existing_dns_zone_resource_group_name": dnsRG,
		"default_node_pool_vm_size":             "Standard_B2s",
		"sku_tier":                              "Free",
		"enable_auto_scaling":                   false,
	}
}

// VerifyBasicOutputs verifies that basic terraform outputs are present and valid
func VerifyBasicOutputs(t *testing.T, terraformOptions *terraform.Options) {
	clusterName := terraform.Output(t, terraformOptions, "cluster_name")
	resourceGroupName := terraform.Output(t, terraformOptions, "resource_group_name")
	resourceGroupLocation := terraform.Output(t, terraformOptions, "resource_group_location")

	assert.NotEmpty(t, clusterName, "cluster_name output should not be empty")
	assert.NotEmpty(t, resourceGroupName, "resource_group_name output should not be empty")
	assert.NotEmpty(t, resourceGroupLocation, "resource_group_location output should not be empty")

	// Verify naming conventions
	assert.Contains(t, clusterName, "aks-", "cluster name should contain 'aks-' prefix")
	assert.Contains(t, resourceGroupName, "rg-", "resource group name should contain 'rg-' prefix")

	t.Logf("✓ Cluster Name: %s", clusterName)
	t.Logf("✓ Resource Group: %s", resourceGroupName)
	t.Logf("✓ Location: %s", resourceGroupLocation)
}

// TestWithCleanup runs a test function with automatic cleanup of terraform resources
func TestWithCleanup(t *testing.T, terraformOptions *terraform.Options, testFunc func(*testing.T, *terraform.Options)) {
	// Ensure cleanup happens even if test fails
	defer func() {
		if r := recover(); r != nil {
			t.Logf("Test panicked, attempting cleanup: %v", r)
			terraform.Destroy(t, terraformOptions)
			panic(r)
		}
	}()

	// Setup cleanup
	t.Cleanup(func() {
		terraform.Destroy(t, terraformOptions)
	})

	// Run the test
	testFunc(t, terraformOptions)
}

// loadEnvVars loads environment variables for Azure authentication
func loadEnvVars() map[string]string {
	return map[string]string{
		"ARM_TENANT_ID":       os.Getenv("ARM_TENANT_ID"),
		"ARM_SUBSCRIPTION_ID": os.Getenv("ARM_SUBSCRIPTION_ID"),
		"ARM_CLIENT_ID":       os.Getenv("ARM_CLIENT_ID"),
		"ARM_CLIENT_SECRET":   os.Getenv("ARM_CLIENT_SECRET"),
	}
}

// LoadEnvFromFile loads environment variables from a .env file if it exists
func LoadEnvFromFile(filePath string) error {
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return nil // File doesn't exist, that's ok
	}

	content, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])
			// Remove quotes if present
			if len(value) >= 2 && ((value[0] == '"' && value[len(value)-1] == '"') || (value[0] == '\'' && value[len(value)-1] == '\'')) {
				value = value[1 : len(value)-1]
			}
			os.Setenv(key, value)
		}
	}

	return nil
}
