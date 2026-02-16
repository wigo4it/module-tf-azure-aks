# AKS Backup and Disaster Recovery Guide

This guide provides comprehensive strategies for backup, restore, and disaster recovery for Azure Kubernetes Service (AKS) clusters.

## Overview

A complete AKS disaster recovery strategy requires:

1. **Cluster Configuration Backup** (Infrastructure as Code)
2. **Application State Backup** (Persistent volumes, databases)
3. **Kubernetes Objects Backup** (Deployments, ConfigMaps, Secrets)
4. **Disaster Recovery Plan** (Multi-region, RTO/RPO targets)

## Backup Strategy

### 1. Infrastructure as Code (IaC) Backup

**This Terraform module already provides IaC backup** through version control.

```bash
# Your cluster configuration is backed up in Git
git clone https://github.com/your-org/infrastructure
cd infrastructure/aks-clusters/production
git log -- main.tf  # View configuration history
```

**Best Practices:**
- ✅ Store Terraform state in Azure Storage with versioning enabled
- ✅ Use Git tags for production releases
- ✅ Enable branch protection for main/production branches
- ✅ Regular state file backups (automated)

**Terraform State Backup:**
```hcl
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"
    container_name       = "tfstate"
    key                  = "aks-prod.tfstate"
    
    # Enable versioning in Azure Storage
    # Portal: Storage Account → Data management → Enable versioning
  }
}
```

### 2. Kubernetes Objects Backup with Velero

[Velero](https://velero.io/) is the industry-standard solution for Kubernetes backup.

#### Installation

```bash
# Install Velero CLI
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xvf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/

# Create Azure Storage Account for backups
AZ_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZURE_BACKUP_RESOURCE_GROUP="velero-backups-rg"
AZURE_STORAGE_ACCOUNT_ID="velerobackups$(uuidgen | cut -d '-' -f 1 | tr '[:upper:]' '[:lower:]')"
BLOB_CONTAINER="velero"

# Create resource group
az group create --name $AZURE_BACKUP_RESOURCE_GROUP --location westeurope

# Create storage account
az storage account create \
  --name $AZURE_STORAGE_ACCOUNT_ID \
  --resource-group $AZURE_BACKUP_RESOURCE_GROUP \
  --sku Standard_GRS \
  --encryption-services blob \
  --https-only true \
  --kind BlobStorage \
  --access-tier Hot

# Create blob container
az storage container create \
  --name $BLOB_CONTAINER \
  --public-access off \
  --account-name $AZURE_STORAGE_ACCOUNT_ID

# Get storage account key
AZURE_STORAGE_ACCOUNT_ACCESS_KEY=$(az storage account keys list \
  --resource-group $AZURE_BACKUP_RESOURCE_GROUP \
  --account-name $AZURE_STORAGE_ACCOUNT_ID \
  --query "[0].value" -o tsv)

# Create credentials file
cat > credentials-velero <<EOF
AZURE_SUBSCRIPTION_ID=${AZ_SUBSCRIPTION_ID}
AZURE_RESOURCE_GROUP=${AZURE_BACKUP_RESOURCE_GROUP}
AZURE_CLOUD_NAME=AzurePublicCloud
AZURE_STORAGE_ACCOUNT_ID=${AZURE_STORAGE_ACCOUNT_ID}
AZURE_STORAGE_ACCOUNT_ACCESS_KEY=${AZURE_STORAGE_ACCOUNT_ACCESS_KEY}
EOF

# Install Velero in cluster
velero install \
  --provider azure \
  --plugins velero/velero-plugin-for-microsoft-azure:v1.8.0 \
  --bucket $BLOB_CONTAINER \
  --secret-file ./credentials-velero \
  --backup-location-config resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,storageAccount=$AZURE_STORAGE_ACCOUNT_ID \
  --snapshot-location-config apiTimeout=5m,resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP \
  --use-node-agent \
  --uploader-type=restic

# Verify installation
kubectl get pods -n velero
```

#### Backup Configurations

**1. Full Cluster Backup (Daily)**

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: daily-full-backup
  namespace: velero
spec:
  schedule: "0 2 * * *"  # 2 AM daily
  template:
    ttl: 720h0m0s  # Retain for 30 days
    includedNamespaces:
    - "*"  # All namespaces
    excludedNamespaces:
    - kube-system
    - kube-public
    - kube-node-lease
    - velero
    storageLocation: default
    volumeSnapshotLocations:
    - default
    defaultVolumesToFsBackup: true  # Backup PVs using file-system backup
```

```bash
# Create the scheduled backup
kubectl apply -f daily-full-backup.yaml

# Verify schedule
velero schedule get
```

**2. Application-Specific Backup**

```yaml
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: production-app-backup
  namespace: velero
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  template:
    ttl: 168h0m0s  # Retain for 7 days
    includedNamespaces:
    - production
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: myapp
        app.kubernetes.io/part-of: production
    defaultVolumesToFsBackup: true
    snapshotVolumes: true
```

**3. Database Backup (with pre/post hooks)**

```yaml
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: postgresql-backup
  namespace: velero
spec:
  includedNamespaces:
  - databases
  labelSelector:
    matchLabels:
      app: postgresql
  hooks:
    resources:
    - name: postgresql-backup-hook
      includedNamespaces:
      - databases
      labelSelector:
        matchLabels:
          app: postgresql
      pre:
      - exec:
          container: postgresql
          command:
          - /bin/bash
          - -c
          - |
            pg_dump -U postgres -d mydb -f /tmp/backup.sql
            echo "Database backup created"
          timeout: 5m
      post:
      - exec:
          container: postgresql
          command:
          - /bin/bash
          - -c
          - rm -f /tmp/backup.sql
  defaultVolumesToFsBackup: true
```

#### Manual Backup Operations

```bash
# Create immediate full backup
velero backup create manual-backup-$(date +%Y%m%d-%H%M%S) \
  --include-namespaces '*' \
  --exclude-namespaces kube-system,kube-public,velero \
  --default-volumes-to-fs-backup

# Backup specific namespace
velero backup create production-backup --include-namespaces production

# Backup with label selector
velero backup create app-backup --selector app=myapp

# List backups
velero backup get

# Describe backup
velero backup describe production-backup

# View backup logs
velero backup logs production-backup

# Download backup
velero backup download production-backup
```

### 3. Persistent Volume Backups

**Azure Disk Snapshots (Automated)**

Velero automatically creates Azure Disk snapshots when `snapshotVolumes: true`:

```yaml
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: volumes-backup
spec:
  includedNamespaces:
  - production
  snapshotVolumes: true  # Creates Azure Disk snapshots
  volumeSnapshotLocations:
  - default
```

**File-System Backup (for all volume types)**

For volumes that don't support snapshots (Azure Files, EmptyDir, HostPath):

```yaml
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: fs-backup
spec:
  includedNamespaces:
  - production
  defaultVolumesToFsBackup: true  # Uses Restic for file-level backup
  snapshotVolumes: false
```

### 4. Application Database Backups

**PostgreSQL Backup with CronJob**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgresql-backup
  namespace: databases
spec:
  schedule: "0 1 * * *"  # 1 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15
            env:
            - name: PGHOST
              value: postgresql.databases.svc.cluster.local
            - name: PGUSER
              valueFrom:
                secretKeyRef:
                  name: postgresql-secret
                  key: username
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgresql-secret
                  key: password
            - name: AZURE_STORAGE_ACCOUNT
              value: "backupstorage"
            - name: AZURE_STORAGE_KEY
              valueFrom:
                secretKeyRef:
                  name: azure-storage-secret
                  key: key
            command:
            - /bin/bash
            - -c
            - |
              set -e
              BACKUP_FILE="postgresql-backup-$(date +%Y%m%d-%H%M%S).sql.gz"
              
              # Create backup
              pg_dumpall | gzip > /tmp/$BACKUP_FILE
              
              # Upload to Azure Blob Storage
              az storage blob upload \
                --account-name $AZURE_STORAGE_ACCOUNT \
                --account-key $AZURE_STORAGE_KEY \
                --container-name db-backups \
                --name $BACKUP_FILE \
                --file /tmp/$BACKUP_FILE
              
              # Cleanup old backups (keep 30 days)
              az storage blob delete-batch \
                --source db-backups \
                --account-name $AZURE_STORAGE_ACCOUNT \
                --account-key $AZURE_STORAGE_KEY \
                --if-unmodified-since $(date -d '30 days ago' -u +"%Y-%m-%dT%H:%M:%SZ")
              
              echo "Backup $BACKUP_FILE uploaded successfully"
          restartPolicy: OnFailure
```

## Restore Procedures

### 1. Full Cluster Restore

**Scenario:** Complete cluster failure, need to restore everything

```bash
# 1. Deploy new AKS cluster using Terraform
cd infrastructure/aks-clusters/production
terraform init
terraform apply

# 2. Get cluster credentials
az aks get-credentials --resource-group rg-production --name prod-cluster

# 3. Install Velero with same credentials
velero install \
  --provider azure \
  --plugins velero/velero-plugin-for-microsoft-azure:v1.8.0 \
  --bucket $BLOB_CONTAINER \
  --secret-file ./credentials-velero \
  --backup-location-config resourceGroup=$AZURE_BACKUP_RESOURCE_GROUP,storageAccount=$AZURE_STORAGE_ACCOUNT_ID

# 4. List available backups
velero backup get

# 5. Restore from latest backup
velero restore create --from-backup daily-full-backup-20260215020000

# 6. Monitor restore
velero restore describe <restore-name>
velero restore logs <restore-name>

# 7. Verify applications
kubectl get pods --all-namespaces
kubectl get pvc --all-namespaces
```

### 2. Namespace Restore

**Scenario:** Accidentally deleted namespace or need to restore specific application

```bash
# Restore specific namespace from backup
velero restore create production-restore \
  --from-backup daily-full-backup-20260215020000 \
  --include-namespaces production

# Or restore to different namespace
velero restore create production-test-restore \
  --from-backup production-backup \
  --namespace-mappings production:production-test
```

### 3. Selective Resource Restore

```bash
# Restore only deployments and services
velero restore create app-restore \
  --from-backup production-backup \
  --include-resources deployments,services \
  --include-namespaces production

# Restore specific resource by label
velero restore create critical-app-restore \
  --from-backup production-backup \
  --selector app=critical-app
```

### 4. Persistent Volume Restore

```bash
# Restore PVCs and their data
velero restore create pvc-restore \
  --from-backup volumes-backup \
  --include-resources persistentvolumeclaims,persistentvolumes

# Verify PVCs restored
kubectl get pvc -n production
```

## Disaster Recovery (DR) Strategy

### RTO and RPO Targets

| Service Tier | RTO (Recovery Time Objective) | RPO (Recovery Point Objective) | Strategy |
|--------------|--------------------------------|--------------------------------|----------|
| Critical | < 1 hour | < 15 minutes | Multi-region active-active + continuous replication |
| Production | < 4 hours | < 1 hour | Multi-region warm standby + hourly backups |
| Standard | < 24 hours | < 24 hours | Single region + daily backups |
| Development | Best effort | N/A | No DR required |

### Multi-Region Architecture

```
┌──────────────── Primary Region (West Europe) ────────────────┐
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AKS Cluster (Active)                               │   │
│  │  - Serve 100% traffic                               │   │
│  │  - Azure Front Door routing                         │   │
│  │  - Continuous backups to Geo-redundant storage      │   │
│  └─────────────────────────────────────────────────────┘   │
│                         │                                     │
│                         │ Velero Backups (GRS)               │
│                         ▼                                     │
└───────────────────────────────────────────────────────────────┘
                          │
                          │ Geo-replication
                          ▼
┌──────────────── Secondary Region (North Europe) ──────────────┐
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  AKS Cluster (Standby)                              │   │
│  │  - Minimal resources (1 node per pool)              │   │
│  │  - Ready for scale-up                               │   │
│  │  - Same Terraform configuration                     │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Velero Restore Point                               │   │
│  │  - Accesses geo-replicated backup storage           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### DR Runbook

**Scenario: Complete Primary Region Failure**

**Detection (0-5 minutes):**
```bash
# Azure Monitor alerts trigger
# Check region health
az resource list --location westeurope --query "[].{name:name,provisioningState:provisioningState}"

# Verify primary cluster unreachable
kubectl cluster-info --context=primary-cluster || echo "Primary cluster OFFLINE"
```

**Decision (5-15 minutes):**
- Assess scope of outage
- Estimate recovery time
- Decide: Wait for recovery vs. Failover to DR

**Failover Execution (15-60 minutes):**

```bash
# 1. Scale up secondary cluster
export KUBECONTEXT=secondary-cluster
kubectl config use-context $KUBECONTEXT

# Scale up node pools
az aks nodepool scale \
  --resource-group rg-dr-northeurope \
  --cluster-name dr-cluster \
  --name user \
  --node-count 10

# 2. Restore applications from backup
velero restore create dr-failover-$(date +%Y%m%d-%H%M%S) \
  --from-backup daily-full-backup-latest \
  --include-namespaces production

# 3. Wait for restore completion
velero restore describe dr-failover-* --details

# 4. Verify application health
kubectl get pods -n production
kubectl get ingress -n production

# 5. Update DNS/Traffic routing
# Azure Front Door: Switch origin priority
az network front-door routing-rule update \
  --front-door-name prod-frontdoor \
  --name default-rule \
  --resource-group rg-frontend \
  --backend-pool dr-backend-pool

# 6. Verify traffic routing
curl -I https://myapp.com | grep -i x-azure-ref
```

**Post-failover (1-4 hours):**
- Monitor secondary cluster performance
- Scale resources as needed
- Communicate status to stakeholders
- Document incident

**Recovery to Primary (when available):**
```bash
# 1. Verify primary region recovered
az resource list --location westeurope

# 2. Deploy/update primary cluster
cd infrastructure/aks-clusters/production-westeurope
terraform apply

# 3. Restore latest data from secondary
# Take backup from secondary (now active)
kubectl config use-context secondary-cluster
velero backup create failback-backup --include-namespaces production --wait

# 4. Restore to primary
kubectl config use-context primary-cluster
velero restore create failback-restore --from-backup failback-backup --wait

# 5. Switch traffic back to primary
az network front-door routing-rule update \
  --front-door-name prod-frontdoor \
  --name default-rule \
  --backend-pool primary-backend-pool

# 6. Scale down secondary to standby
az aks nodepool scale \
  --resource-group rg-dr-northeurope \
  --cluster-name dr-cluster \
  --name user \
  --node-count 1
```

## Testing DR Plan

### Quarterly DR Test

```bash
# 1. Schedule maintenance window
# 2. Simulate primary failure (DO NOT DO IN PRODUCTION without approval)

# Test restore to DR cluster
kubectl config use-context dr-test-cluster

# Restore latest production backup
velero restore create dr-test-$(date +%Y%m%d) \
  --from-backup production-latest \
  --namespace-mappings production:production-dr-test

# 3. Verify application functionality
kubectl get pods -n production-dr-test
kubectl exec -it <app-pod> -n production-dr-test -- curl localhost:8080/health

# 4. Measure RTO achieved
# Record time from restore initiation to application ready

# 5. Document findings and update runbook

# 6. Cleanup test resources
kubectl delete namespace production-dr-test
```

## Backup Verification

### Monthly Backup Validation

```bash
# Restore backup to isolated namespace for validation
velero restore create validation-$(date +%Y%m) \
  --from-backup daily-full-backup-latest \
  --namespace-mappings production:validation-prod

# Verify resources
kubectl get all -n validation-prod

# Cleanup
kubectl delete namespace validation-prod
```

## Backup Retention Policy

| Backup Type | Frequency | Retention | Purpose |
|-------------|-----------|-----------|---------|
| Full Cluster | Daily | 30 days | Complete recovery |
| Application | 6 hours | 7 days | Recent state recovery |
| Database | Hourly | 7 days | Point-in-time recovery |
| Monthly Archive | Monthly | 1 year | Compliance/Audit |

## Cost Optimization for Backups

```bash
# Lifecycle management for backup storage
az storage account management-policy create \
  --account-name $AZURE_STORAGE_ACCOUNT_ID \
  --policy @policy.json

# policy.json
{
  "rules": [
    {
      "name": "move-to-cool-after-30-days",
      "type": "Lifecycle",
      "definition": {
        "actions": {
          "baseBlob": {
            "tierToCool": {
              "daysAfterModificationGreaterThan": 30
            },
            "tierToArchive": {
              "daysAfterModificationGreaterThan": 90
            },
            "delete": {
              "daysAfterModificationGreaterThan": 365
            }
          }
        },
        "filters": {
          "blobTypes": ["blockBlob"],
          "prefixMatch": ["velero/"]
        }
      }
    }
  ]
}
```

**Cost Analysis:**
- Hot tier (first 30 days): $0.02/GB/month
- Cool tier (30-90 days): $0.01/GB/month
- Archive tier (90-365 days): $0.002/GB/month
- **Estimated savings**: 60-80% over 1 year

## Well-Architected Framework Impact

| Pillar | Score Impact | Justification |
|--------|--------------|---------------|
| Reliability | +2 points (92→94/100) | Comprehensive backup/restore capability with validated DR plan |
| Operational Excellence | +1 point (87→88/100) | Automated backup processes and documented runbooks |
| Cost Optimization | +1 point | Optimized backup retention with lifecycle policies |

**Overall WAF Score Improvement**: +2-3 points (95→97-98/100)

## Additional Resources

- [Velero Documentation](https://velero.io/docs/)
- [Azure Backup for AKS](https://learn.microsoft.com/azure/backup/azure-kubernetes-service-cluster-backup)
- [AKS Disaster Recovery](https://learn.microsoft.com/azure/aks/operator-best-practices-multi-region)
- [Azure Storage Lifecycle Management](https://learn.microsoft.com/azure/storage/blobs/lifecycle-management-overview)
