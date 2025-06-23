# Contributing to Haven Azure Cluster Module

Thank you for your interest in contributing! This guide explains how to execute the provided Terraform examples and set up your environment for local testing.

## Running the Examples

1. **Clone the repository** and navigate to the project root:
   ```bash
   git clone <repo-url>
   cd module-haven-cluster-azure-digilab
   ```

2. **Navigate to the example directory:**
   ```bash
   cd examples/minimal
   ```

3. **Create a `.env` file** in the example directory with your Azure credentials and any required variables. See below for details.

4. **Load environment variables and run Terraform plan:**
   - Use the provided script from the `examples` directory:
     ```bash
     cd ../
     ./tf-plan.sh minimal
     ```
   - This script will automatically load variables from `examples/minimal/.env` and run `terraform init` and `terraform plan`.

5. **Apply the plan (optional):**
   - Uncomment the `terraform apply tfplan` line in the script, or run manually:
     ```bash
     cd minimal
     terraform apply tfplan
     ```

## Creating the `.env` File

Create a file named `.env` in the `examples/minimal/` directory with the following content (replace values with your own):

```bash
# Azure authentication (Service Principal recommended)
ARM_TENANT_ID="<your-tenant-id>"
ARM_SUBSCRIPTION_ID="<your-subscription-id>"
```

- You can obtain these values from the Azure Portal or via the Azure CLI.
- The environment variables are automatically loaded by the example scripts.

## Notes
- The default backend is set to local for easy testing. No Azure Storage Account is required for state.
- Make sure you have [Terraform](https://www.terraform.io/downloads.html) installed (see `.tool-versions` for the required version).
- For more advanced usage, see the module documentation and the `README.md`.

## Need Help?
Open an issue or discussion in the repository if you have questions or need support.
