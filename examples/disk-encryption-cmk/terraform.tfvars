cluster_name       = "cmk-encrypted-cluster"
location           = "westeurope"
kubernetes_version = "1.30.0"
key_vault_name     = "kv-aks-cmk-unique123"

# Azure AD group object IDs for cluster admins
# Replace with your actual Azure AD group object IDs
admin_group_object_ids = [
  "00000000-0000-0000-0000-000000000000"
]
