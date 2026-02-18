# Multi-Region AKS Architecture

This guide provides strategies for designing and operating multi-region Azure Kubernetes Service (AKS) deployments to achieve high availability, disaster recovery, and optimal performance.

## Architecture Patterns

### 1. Active-Passive (Warm Standby)

**Use Case:** Cost-effective DR for most production workloads

```
┌─────────── Primary Region (West Europe) ───────────┐
│                                                     │
│  AKS Cluster: 10 nodes                            │
│  Traffic: 100%                                     │
│  Databases: Active (Primary)                       │
│  Cost: $2,000/month                                │
│                                                     │
└─────────────────────────────────────────────────────┘
                    │
                    │ Replication
                    ▼
┌────────── Secondary Region (North Europe) ──────────┐
│                                                     │
│  AKS Cluster: 2 nodes (minimal)                    │
│  Traffic: 0%                                       │
│  Databases: Read Replica                           │
│  Cost: $400/month                                  │
│                                                     │
└─────────────────────────────────────────────────────┘

Total Cost: $2,400/month
RTO: 15-30 minutes
RPO: < 5 minutes
```

### 2. Active-Active (Multi-Master)

**Use Case:** Global applications requiring lowest latency and zero downtime

```
┌─────────── West Europe ───────────┐   ┌─────────── North Europe ───────────┐
│                                   │   │                                    │
│  AKS Cluster: 10 nodes           │   │  AKS Cluster: 10 nodes            │
│  Traffic: 50%                     │◄─►│  Traffic: 50%                     │
│  Databases: Active (Sync)         │   │  Databases: Active (Sync)         │
│  Cost: $2,000/month               │   │  Cost: $2,000/month               │
│                                   │   │                                    │
└───────────────────────────────────┘   └────────────────────────────────────┘
                    │                                     │
                    │          Azure Front Door           │
                    │        (Geo-load balancing)         │
                    │                                     │
                    └─────────────┬───────────────────────┘
                                  │
                              End Users
                                  │
                    Routed to nearest healthy region

Total Cost: $4,000/month + global routing
RTO: < 1 minute (automatic failover)
RPO: 0 (synchronous replication)
```

### 3. Hub-Spoke (Regional Hubs)

**Use Case:** Multi-region with centralized services

```
┌──────────────────── Central Hub (West Europe) ────────────────────┐
│                                                                    │
│  Shared Services:                                                 │
│  - Azure Firewall                                                 │
│  - Azure Bastion                                                  │
│  - Log Analytics (central)                                        │
│  - Azure Container Registry                                       │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
           │                           │                           │
           │                           │                           │
           ▼                           ▼                           ▼
┌─── West Europe ───┐    ┌─── North Europe ───┐    ┌─── East US ───┐
│                   │    │                     │    │                │
│  AKS: 10 nodes   │    │  AKS: 10 nodes     │    │  AKS: 10 nodes│
│  Traffic: 40%     │    │  Traffic: 40%       │    │  Traffic: 20% │
│  VNet Peering     │    │  VNet Peering       │    │  VNet Peering │
│                   │    │                     │    │                │
└───────────────────┘    └─────────────────────┘    └────────────────┘
```

## Region Selection Criteria

### Choosing Regions

| Factor | Importance | Considerations |
|--------|------------|----------------|
| **Latency** | Critical | Regional pairs < 50ms latency |
| **Compliance** | Critical | Data residency requirements (GDPR, etc.) |
| **Availability** | High | Azure region pairs for SLA |
| **Cost** | Medium | Price varies by region (~10-20% difference) |
| **Features** | Medium | Not all services available in all regions |
| **Availability Zones** | High | Select regions with 3+ AZs |

### Recommended Region Pairs

| Primary | Secondary | Latency | Use Case |
|---------|-----------|---------|----------|
| West Europe | North Europe | ~30ms | European customers, GDPR compliance |
| East US | West US 2 | ~60ms | US customers |
| Southeast Asia | East Asia | ~40ms | APAC customers |
| UK South | UK West | ~15ms | UK customers, data sovereignty |

## Traffic Routing

### Azure Front Door Configuration

```hcl
# Terraform configuration for multi-region routing
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "aks-multiregion-profile"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Premium_AzureFrontDoor"  # Required for WAF
  
  tags = {
    environment = "production"
    routing     = "multi-region"
  }
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "multiregion-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  
  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }
  
  health_probe {
    path                = "/health"
    request_type        = "GET"
    protocol            = "Https"
    interval_in_seconds = 30
  }
}

# Primary region origin (West Europe)
resource "azurerm_cdn_frontdoor_origin" "primary" {
  name                           = "primary-westeurope"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main.id
  
  enabled                        = true
  host_name                      = "westeurope.myapp.com"
  http_port                      = 80
  https_port                     = 443
  priority                       = 1  # Primary
  weight                         = 1000
  
  certificate_name_check_enabled = true
}

# Secondary region origin (North Europe)
resource "azurerm_cdn_frontdoor_origin" "secondary" {
  name                           = "secondary-northeurope"
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.main.id
  
  enabled                        = true
  host_name                      = "northeurope.myapp.com"
  http_port                      = 80
  https_port                     = 443
  priority                       = 2  # Failover
  weight                         = 1000
  
  certificate_name_check_enabled = true
}

resource "azurerm_cdn_frontdoor_route" "main" {
  name                            = "default-route"
  cdn_frontdoor_endpoint_id       = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids        = [
    azurerm_cdn_frontdoor_origin.primary.id,
    azurerm_cdn_frontdoor_origin.secondary.id,
  ]
  
  patterns_to_match = ["/*"]
  supported_protocols = ["Http", "Https"]
  https_redirect_enabled = true
  
  forwarding_protocol = "HttpsOnly"
  link_to_default_domain = true
}
```

### Routing Strategies

**1. Priority-Based (Active-Passive)**
```hcl
# Primary: priority 1, weight 1000
# Secondary: priority 2, weight 1000
# Result: All traffic to primary unless unhealthy
```

**2. Weighted Round-Robin (Active-Active)**
```hcl
# West Europe: priority 1, weight 70  (70% traffic)
# North Europe: priority 1, weight 30 (30% traffic)
# Result: Traffic split 70/30
```

**3. Latency-Based (Geo-proximity)**
```hcl
# Enable session affinity: routes users to nearest healthy origin
session_affinity_enabled = true
```

## Data Replication

### Stateless Applications

**Approach:** Deploy identical code to all regions, no data sync needed.

```yaml
# Kubernetes deployment (same in all regions)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 10
  template:
    spec:
      containers:
      - name: app
        image: myregistry.azurecr.io/web-app:v1.2.0  # Multi-region ACR replication
        env:
        - name: REGION
          value: "westeurope"  # Change per region
```

**Azure Container Registry Geo-Replication:**
```bash
# Enable geo-replication for container images
az acr replication create \
  --registry myregistry \
  --location northeurope

# Images automatically synchronized to all replicas
# Each region pulls from local replica (low latency)
```

### Stateful Applications

#### 1. Azure Cosmos DB (Global Distribution)

**Best for:** Multi-region read/write with automatic failover

```hcl
resource "azurerm_cosmosdb_account" "main" {
  name                = "myapp-cosmosdb"
  resource_group_name = azurerm_resource_group.main.name
  location            = "westeurope"
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  
  consistency_policy {
    consistency_level       = "Session"  # Balance between consistency and performance
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }
  
  geo_location {
    location          = "westeurope"
    failover_priority = 0  # Primary
  }
  
  geo_location {
    location          = "northeurope"
    failover_priority = 1  # Secondary
  }
  
  enable_automatic_failover = true
  enable_multiple_write_locations = true  # Active-active writes
}
```

**Consistency Levels:**
- **Strong:** Guarantees linearizability (highest latency)
- **Session:** Consistent within session (recommended)
- **Eventual:** Lowest latency, eventual consistency

#### 2. Azure Database for PostgreSQL (Read Replicas)

```bash
# Create read replica in secondary region
az postgres flexible-server replica create \
  --name postgres-northeurope \
  --resource-group rg-northeurope \
  --source-server postgres-westeurope

# Application configuration
# Primary: postgres-westeurope.postgres.database.azure.com (read-write)
# Replica: postgres-northeurope.postgres.database.azure.com (read-only)
```

**Failover Process:**
```bash
# Promote replica to standalone server
az postgres flexible-server replica stop-replication \
  --name postgres-northeurope \
  --resource-group rg-northeurope

# Update application to write to new primary
kubectl set env deployment/app \
  DATABASE_HOST=postgres-northeurope.postgres.database.azure.com
```

#### 3. Persistent Volumes (Cross-Region)

**Azure Files with GRS:**
```hcl
resource "azurerm_storage_account" "main" {
  name                     = "multiregionstorage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = "westeurope"
  account_tier             = "Standard"
  account_replication_type = "GZRS"  # Geo-zone-redundant storage
  
  # Automatic failover enabled
}

# Data replicated to paired region (North Europe)
# Failover: az storage account failover --name multiregionstorage
```

**Velero Backups (Disaster Recovery):**
```bash
# Backup in primary region
velero backup create cross-region-backup \
  --storage-location primary

# Storage account with GRS automatically replicates to secondary
# Restore in secondary region after failover
velero restore create --from-backup cross-region-backup
```

## Multi-Region Deployment Example

### Directory Structure
```
infrastructure/
├── global/
│   ├── front-door.tf        # Global traffic routing
│   ├── container-registry.tf # Multi-region ACR
│   └── cosmosdb.tf           # Global database
├── westeurope/
│   ├── main.tf               # AKS cluster (primary)
│   ├── terraform.tfvars
│   └── backend.tf
└── northeurope/
    ├── main.tf               # AKS cluster (secondary)
    ├── terraform.tfvars
    └── backend.tf
```

### Primary Region (westeurope/main.tf)

```hcl
module "aks_primary" {
  source = "../../modules/default"
  
  cluster_name        = "prod-westeurope"
  resource_group_name = "rg-prod-westeurope"
  location            = "westeurope"
  
  kubernetes_version = "1.30.0"
  
  node_pools = {
    system = {
      vm_size    = "Standard_D4s_v5"
      node_count = 3
      min_count  = 3
      max_count  = 6
      mode       = "System"
    }
    user = {
      vm_size    = "Standard_D8s_v5"
      node_count = 5
      min_count  = 5
      max_count  = 20
      mode       = "User"
    }
  }
  
  # Multi-region specific
  tags = {
    environment = "production"
    region      = "primary"
    dr_pair     = "northeurope"
  }
  
  # Monitoring (central Log Analytics)
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.central.id
}

# Kubernetes configuration for multi-region awareness
resource "kubernetes_config_map" "region_info" {
  metadata {
    name      = "region-info"
    namespace = "kube-system"
  }
  
  data = {
    region   = "westeurope"
    role     = "primary"
    dr_pair  = "northeurope"
  }
}
```

### Secondary Region (northeurope/main.tf)

```hcl
module "aks_secondary" {
  source = "../../modules/default"
  
  cluster_name        = "prod-northeurope"
  resource_group_name = "rg-prod-northeurope"
  location            = "northeurope"
  
  kubernetes_version = "1.30.0"  # Match primary version
  
  node_pools = {
    system = {
      vm_size    = "Standard_D4s_v5"
      node_count = 3
      min_count  = 3
      max_count  = 6
      mode       = "System"
    }
    user = {
      vm_size    = "Standard_D8s_v5"
      node_count = 2  # Minimal for standby
      min_count  = 2
      max_count  = 20  # Can scale to same as primary
      mode       = "User"
    }
  }
  
  tags = {
    environment = "production"
    region      = "secondary"
    dr_pair     = "westeurope"
  }
  
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.central.id
}
```

## Application Configuration

### Region-Aware Deployments

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 10
  template:
    spec:
      containers:
      - name: app
        image: myregistry.azurecr.io/web-app:v1.2.0
        env:
        # Region information from ConfigMap
        - name: AZURE_REGION
          valueFrom:
            configMapKeyRef:
              name: region-info
              key: region
        - name: REGION_ROLE
          valueFrom:
            configMapKeyRef:
              name: region-info
              key: role
        
        # Database connection (region-specific)
        - name: DATABASE_HOST
          value: "postgres-westeurope.postgres.database.azure.com"
        - name: DATABASE_READ_REPLICAS
          value: "postgres-westeurope.postgres.database.azure.com,postgres-northeurope.postgres.database.azure.com"
        
        # Cache (region-specific)
        - name: REDIS_HOST
          value: "redis-westeurope.redis.cache.windows.net"
        
        # Feature flags for multi-region
        - name: ENABLE_CROSS_REGION_CALLS
          value: "true"
        - name: CROSS_REGION_TIMEOUT_MS
          value: "2000"
```

### Health Checks for Routing

```go
// Kubernetes health endpoint with region failover awareness
func healthHandler(w http.ResponseWriter, r *http.Request) {
    region := os.Getenv("AZURE_REGION")
    
    // Check local dependencies
    dbHealthy := checkDatabase()
    cacheHealthy := checkCache()
    
    if !dbHealthy || !cacheHealthy {
        // Respond with 503 to trigger Front Door failover
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]interface{}{
            "status": "unhealthy",
            "region": region,
            "database": dbHealthy,
            "cache": cacheHealthy,
        })
        return
    }
    
    // Healthy response
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]interface{}{
        "status": "healthy",
        "region": region,
    })
}
```

## Monitoring Multi-Region Setup

### Azure Monitor Workbook (Cross-Region)

```kusto
// Query for multi-region availability
let timeRange = 1h;
AzureDiagnostics
| where TimeGenerated > ago(timeRange)
| where ResourceType == "FRONTDOORS"
| summarize 
    TotalRequests = count(),
    Errors = countif(httpStatus_d >= 500),
    AvgLatency = avg(timeTaken_d)
  by Region = tostring(split(requestUri_s, '.')[0])
| extend AvailabilityPercent = 100.0 * (TotalRequests - Errors) / TotalRequests
| project Region, AvailabilityPercent, AvgLatency, TotalRequests, Errors
```

### Grafana Dashboard (Multi-Region)

```yaml
# Prometheus queries for multi-region metrics
- name: Multi-Region Availability
  query: |
    sum(rate(http_requests_total{job="web-app"}[5m])) by (region)

- name: Cross-Region Latency
  query: |
    histogram_quantile(0.95, 
      sum(rate(http_request_duration_seconds_bucket{job="web-app"}[5m])) by (region, le)
    )

- name: Failover Events
  query: |
    increase(frontdoor_failover_total[1h])
```

### Alerts

```hcl
resource "azurerm_monitor_metric_alert" "region_failover" {
  name                = "region-failover-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_cdn_frontdoor_profile.main.id]
  
  criteria {
    metric_namespace = "Microsoft.Cdn/profiles"
    metric_name      = "OriginHealthPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 80  # Alert if origin health < 80%
  }
  
  action {
    action_group_id = azurerm_monitor_action_group.critical.id
  }
  
  severity = 1  # Critical
}
```

## Cost Analysis

### Active-Passive Cost Comparison

| Component | Primary | Secondary | Total |
|-----------|---------|-----------|-------|
| **AKS Compute** | $1,600 | $320 (20% of primary) | $1,920 |
| **Load Balancer** | $25 | $25 | $50 |
| **Front Door** | - | - | $150 |
| **Storage (GRS)** | $80 | Included | $80 |
| **Cosmos DB** | $400 | $400 | $800 |
| **Egress Traffic** | $50 | $10 | $60 |
| **Monitoring** | $100 | $100 | $200 |
| **Total/month** | $2,255 | $855 | **$3,260** |

**vs. Single Region:** $2,100/month  
**Premium:** +$1,160/month (+55%) for DR capability

### Active-Active Cost Comparison

| Component | Total/month |
|-----------|-------------|
| AKS Compute (2x) | $3,200 |
| Front Door (Premium) | $250 |
| Storage (GRS) | $80 |
| Cosmos DB (multi-write) | $1,200 |
| Egress Traffic | $150 |
| Monitoring | $200 |
| **Total** | **$5,080** |

**vs. Single Region:** $2,100/month  
**Premium:** +$2,980/month (+142%) for zero-downtime HA

## Best Practices

### ✅ DO

1. **Use Azure region pairs** for automatic geo-replication
2. **Test failover quarterly** with documented runbooks
3. **Monitor cross-region latency** continuously
4. **Implement health checks** for automatic failover
5. **Use managed services** (Cosmos DB, Front Door) for replication
6. **Version infrastructure as code** identically across regions
7. **Centralize logging** in one Log Analytics workspace
8. **Automate deployments** (CI/CD to all regions)

### ❌ DON'T

1. ❌ Deploy different application versions across regions
2. ❌ Rely on synchronous cross-region calls (high latency)
3. ❌ Forget to test restore from geo-replicated backups
4. ❌ Use strong consistency unless required (high latency penalty)
5. ❌ Over-provision secondary region in active-passive
6. ❌ Ignore egress costs for cross-region replication
7. ❌ Deploy without traffic routing strategy

## Migration from Single to Multi-Region

### Phase 1: Preparation (Week 1-2)
- [ ] Document current architecture
- [ ] Identify stateful components
- [ ] Choose secondary region
- [ ] Calculate cost increase
- [ ] Get stakeholder approval

### Phase 2: Infrastructure (Week 3-4)
- [ ] Deploy secondary AKS cluster
- [ ] Configure Azure Front Door
- [ ] Set up geo-replication (storage, database)
- [ ] Implement monitoring

### Phase 3: Application Updates (Week 5-6)
- [ ] Add region awareness to applications
- [ ] Implement health endpoints
- [ ] Update CI/CD for multi-region
- [ ] Test cross-region communication

### Phase 4: Testing (Week 7-8)
- [ ] Functional testing in secondary
- [ ] Failover testing
- [ ] Performance testing
- [ ] Load testing with traffic split

### Phase 5: Production Cutover (Week 9)
- [ ] Enable Front Door routing
- [ ] Monitor for 48 hours
- [ ] Gradually increase secondary traffic (active-active)
- [ ] Document lessons learned

## Well-Architected Framework Impact

| Pillar | Score Impact | Justification |
|--------|--------------|---------------|
| Reliability | +1 point (94→95/100) | Multi-region architecture eliminates single region as point of failure |
| Performance | +1 point | Lower latency through geo-proximity routing |

## Additional Resources

- [Azure Region Pairs](https://learn.microsoft.com/azure/reliability/cross-region-replication-azure)
- [Azure Front Door Documentation](https://learn.microsoft.com/azure/frontdoor/)
- [Multi-Region AKS](https://learn.microsoft.com/azure/aks/operator-best-practices-multi-region)
- [Cosmos DB Global Distribution](https://learn.microsoft.com/azure/cosmos-db/distribute-data-globally)
- [AKS Disaster Recovery](https://learn.microsoft.com/azure/aks/operator-best-practices-multi-region)
