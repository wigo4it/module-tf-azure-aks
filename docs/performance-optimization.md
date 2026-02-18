# Performance Optimization Guide

This guide provides best practices for optimizing the performance and resource utilization of your AKS cluster.

## Resource Requests and Limits

### Why They Matter

Setting proper resource requests and limits is critical for:
- **Cluster Stability**: Prevents resource starvation and node crashes
- **Cost Optimization**: Efficient resource allocation avoids over-provisioning
- **Performance**: Ensures predictable application behavior
- **Autoscaling**: Cluster autoscaler makes better scaling decisions

### Best Practices

#### 1. Always Set Resource Requests

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp
spec:
  containers:
  - name: app
    image: myapp:latest
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

**CPU Requests:**
- Start with `100m` (0.1 CPU) for lightweight services
- Use `250m-500m` for typical web applications
- Use `1000m+` for compute-intensive workloads
- Monitor actual usage and adjust

**Memory Requests:**
- Start with `128Mi` for lightweight services
- Use `256Mi-512Mi` for typical web applications
- Use `1Gi+` for memory-intensive workloads (databases, caches)
- Set limits 1.5-2x higher than requests for burst capacity

#### 2. Set Memory Limits Carefully

**Critical:** Always set memory limits to prevent OOM (Out of Memory) kills:

```yaml
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "512Mi"  # 2x request for burst capacity
```

**Warning:** Missing memory limits can cause:
- Node memory exhaustion
- Kernel OOM killer terminating critical processes
- Cluster instability

#### 3. CPU Limits - Use Cautiously

**Recommendation:** Set CPU limits only when necessary:

```yaml
# Good: Allows CPU bursting
resources:
  requests:
    cpu: "250m"
  # No CPU limit - can burst when available

# Use limits only for:
# - Noisy neighbors that need throttling
# - Guaranteed QoS class requirements
resources:
  requests:
    cpu: "500m"
  limits:
    cpu: "1000m"  # Maximum 1 CPU core
```

**Why:** CPU limits can cause unexpected throttling even when CPU is available, leading to increased latency.

### Quality of Service (QoS) Classes

Kubernetes assigns QoS classes based on resource configuration:

#### Guaranteed (Highest Priority)
```yaml
# Requests = Limits for both CPU and memory
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "256Mi"
    cpu: "250m"
```
**Use for:** Critical production workloads, databases

#### Burstable (Medium Priority)
```yaml
# Requests < Limits OR only requests set
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    # No CPU limit
```
**Use for:** Most production applications (recommended)

#### BestEffort (Lowest Priority)
```yaml
# No requests or limits
resources: {}
```
**Use for:** Development, testing, batch jobs (avoid in production)

## Node Pool Sizing

### System Node Pool (mode: "System")

**Purpose:** Kubernetes system pods (CoreDNS, metrics-server, etc.)

**Recommended Configuration:**
```hcl
aks_default_node_pool = {
  vm_size = "Standard_DC2ads_v6"  # 2 vCPUs, 8 GB RAM
  node_count = 3
  mode = "System"
  max_pods = 250
  only_critical_addons_enabled = false
  
  cluster_auto_scaling_enabled = true
  cluster_auto_scaling_min_count = 3
  cluster_auto_scaling_max_count = 6
}
```

**Sizing Guidelines:**
- **Min 3 nodes** for high availability across 3 availability zones
- **2-4 vCPUs per node** sufficient for system workloads
- **8-16 GB RAM per node** for system pods
- **Max pods: 250** (Azure CNI Overlay default)

### User Node Pool (mode: "User")

**Purpose:** Your application workloads

**Recommended Configuration:**
```hcl
aks_additional_node_pools = {
  user = {
    vm_size = "Standard_D4s_v5"  # 4 vCPUs, 16 GB RAM
    node_count = 3
    mode = "User"
    max_pods = 250
    
    cluster_auto_scaling_enabled = true
    cluster_auto_scaling_min_count = 2
    cluster_auto_scaling_max_count = 10
    
    labels = {
      workload = "general"
    }
  }
}
```

**Sizing Decision Matrix:**

| Workload Type | VM Size | vCPUs | RAM | Max Pods/Node | Use Case |
|---------------|---------|-------|-----|---------------|----------|
| Lightweight | Standard_D2s_v5 | 2 | 8 GB | 250 | Small microservices |
| General | Standard_D4s_v5 | 4 | 16 GB | 250 | Web apps, APIs |
| Memory-intensive | Standard_E4s_v5 | 4 | 32 GB | 250 | Databases, caches |
| CPU-intensive | Standard_F8s_v2 | 8 | 16 GB | 250 | Data processing |
| High-density | Standard_D8s_v5 | 8 | 32 GB | 250 | Many small pods |

## Horizontal Pod Autoscaler (HPA)

### Basic HPA Configuration

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60  # Max 50% pods removed per minute
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15  # Max 100% pods added per 15 seconds
```

**Key Recommendations:**
- **Min replicas: 3+** for high availability
- **CPU target: 60-80%** utilization (70% recommended)
- **Memory target: 70-85%** utilization (80% recommended)
- **Scale down slowly:** Prevent flapping (5-10 min stabilization)
- **Scale up quickly:** Respond to load spikes (0-30 sec stabilization)

### Custom Metrics HPA

For more advanced scenarios, use custom metrics:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-custom-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 20
  metrics:
  # CPU utilization
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  
  # Request rate (from ingress controller)
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  
  # Queue depth (from Azure Service Bus)
  - type: External
    external:
      metric:
        name: azure_servicebus_messages
        selector:
          matchLabels:
            queue: "orders"
      target:
        type: AverageValue
        averageValue: "30"
```

## Cluster Autoscaler

### Configuration Best Practices

The cluster autoscaler is configured in your Terraform:

```hcl
aks_additional_node_pools = {
  user = {
    vm_size = "Standard_D4s_v5"
    
    cluster_auto_scaling_enabled = true
    cluster_auto_scaling_min_count = 3
    cluster_auto_scaling_max_count = 20
    
    # Important: Set appropriate upgrade settings
    upgrade_settings = {
      drain_timeout_in_minutes = 10
      max_surge = "33%"
    }
  }
}
```

**Sizing Recommendations:**
- **Min count:** Match high-availability requirements (min 3 for HA)
- **Max count:** Set based on budget and capacity planning
- **Surge:** 33% allows faster scaling and smoother upgrades

### PodDisruptionBudgets (PDB)

Ensure cluster autoscaler respects availability during scale-down:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
---
# Alternative: Use maxUnavailable
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb-percent
spec:
  maxUnavailable: 1  # Or "25%" for percentage
  selector:
    matchLabels:
      app: myapp
```

**Best Practices:**
- Always set PDBs for production workloads
- `minAvailable: 2` for 3+ replica services
- `minAvailable: 1` for 2 replica services
- Use `maxUnavailable: 1` to allow rolling updates

## Network Performance

### Azure CNI Overlay (Recommended)

This module uses Azure CNI Overlay by default:

```hcl
network_profile = {
  network_plugin = "azure"
  network_plugin_mode = "overlay"
  network_policy = "calico"
  pod_cidr = "10.244.0.0/16"
}
```

**Benefits:**
- **250 pods/node** (vs 30-110 with legacy CNI)
- **No VNet IP exhaustion** (pods use separate CIDR)
- **Better performance** than Kubenet
- **Lower latency** than traditional CNI

### Network Policies

Use Calico network policies to optimize traffic flow:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 9000
  - to:  # Allow DNS
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

## Storage Performance

### Disk SKU Selection

**Available Options:**
- **Standard HDD:** $0.05/GB/month, 500 IOPS, 60 MB/s - Use for backups, logs
- **Standard SSD:** $0.08/GB/month, 500 IOPS, 60 MB/s - Use for dev/test
- **Premium SSD:** $0.14/GB/month, 5000 IOPS, 200 MB/s - **Recommended for production**
- **Premium SSD v2:** Variable pricing, up to 80,000 IOPS - Use for high-performance databases

**StorageClass Example:**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS  # Premium SSD
  kind: Managed
  cachingMode: ReadWrite
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer  # Important: Ensures volume created in same zone as pod
allowVolumeExpansion: true
```

### Volume Performance Tuning

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgresql-data
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: fast-ssd
  resources:
    requests:
      storage: 100Gi  # Larger volume = better IOPS for Premium SSD
```

**Premium SSD IOPS Scale:**
- 32 GB = 120 IOPS
- 64 GB = 240 IOPS
- 128 GB = 500 IOPS
- 256 GB = 1,100 IOPS
- 512 GB = 2,300 IOPS
- 1 TB = 5,000 IOPS

## Monitoring and Profiling

### Key Metrics to Monitor

**Node-Level Metrics:**
```bash
# View node resource usage
kubectl top nodes

# Detailed node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"
```

**Pod-Level Metrics:**
```bash
# View pod resource usage
kubectl top pods -A

# Pods using most memory
kubectl top pods -A --sort-by=memory

# Pods using most CPU
kubectl top pods -A --sort-by=cpu
```

### Azure Monitor Integration

This module configures Azure Monitor automatically. Key metric alerts:

| Alert | Threshold | Action |
|-------|-----------|--------|
| Node CPU | > 80% | Investigate workloads, consider scaling |
| Node Memory | > 85% | Check for memory leaks, increase node size |
| Pod Restarts | > 5 in 15 min | Check application logs, resource limits |
| Disk Usage | > 85% | Clean up images, expand disk |

## Performance Testing

### Load Testing Recommendations

1. **Baseline Testing:**
```bash
# Install k6 for load testing
kubectl apply -f https://raw.githubusercontent.com/grafana/k6-operator/main/bundle.yaml

# Run load test
kubectl create configmap k6-test --from-file=test.js
kubectl apply -f k6-job.yaml
```

2. **Gradual Load Increase:**
- Start with 10 RPS (requests per second)
- Increase by 50% every 5 minutes
- Monitor CPU, memory, latency, error rate
- Identify breaking point

3. **Monitoring During Tests:**
```bash
# Watch resource usage
watch kubectl top pods

# View HPA scaling
watch kubectl get hpa

# View cluster autoscaler logs
kubectl logs -n kube-system -l app=cluster-autoscaler
```

## Common Performance Anti-Patterns

### ❌ Don't Do This

**1. No Resource Requests**
```yaml
# BAD: No requests/limits
spec:
  containers:
  - name: app
    image: myapp:latest
    # No resources defined
```

**2. Tiny Resource Requests**
```yaml
# BAD: Too small, causes constant scaling
resources:
  requests:
    cpu: "10m"
    memory: "32Mi"
```

**3. CPU Limits on Critical Services**
```yaml
# BAD: Can cause unexpected throttling
resources:
  requests:
    cpu: "500m"
  limits:
    cpu: "500m"  # Prevents bursting
```

**4. Single Replica**
```yaml
# BAD: No high availability
spec:
  replicas: 1  # Single point of failure
```

### ✅ Do This Instead

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3  # HA across zones
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      # Spread across availability zones
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: myapp
      
      containers:
      - name: app
        image: myapp:latest
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            # No CPU limit - allow bursting
        
        # Readiness probe for load balancing
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
        
        # Liveness probe for restart
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
```

## Optimization Checklist

- [ ] All pods have resource requests set
- [ ] Memory limits set for all production pods
- [ ] CPU limits avoided (unless specifically needed)
- [ ] HPA configured for variable workloads
- [ ] PodDisruptionBudgets set for HA services
- [ ] Node pools use autoscaling
- [ ] Premium SSD used for production databases
- [ ] Network policies configured
- [ ] Monitoring alerts configured
- [ ] Load testing performed
- [ ] Resource usage monitored and tuned

## Additional Resources

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [AKS Best Practices](https://learn.microsoft.com/azure/aks/best-practices)
- [Azure CNI Overlay](https://learn.microsoft.com/azure/aks/azure-cni-overlay)
- [Cluster Autoscaler](https://learn.microsoft.com/azure/aks/cluster-autoscaler)
- [HPA Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
