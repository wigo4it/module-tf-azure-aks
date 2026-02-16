# Pod Security Standards Example - Production Configuration

This example demonstrates a production-ready AKS cluster with **Pod Security Standards** enforced via Azure Policy for Kubernetes.

## 🔒 Security Configuration

### Pod Security Standards - Baseline Level (Deny Mode)

```terraform
pod_security_policy = {
  enabled             = true
  level               = "baseline"  # Prevents known privilege escalations
  effect              = "deny"      # BLOCKS non-compliant deployments
  excluded_namespaces = ["monitoring"]  # Custom exclusions if needed
}
```

### What Baseline Level Blocks

The **baseline** policy prevents:
- ✅ Privileged containers (`securityContext.privileged: true`)
- ✅ Host namespace sharing (hostNetwork, hostPID, hostIPC)
- ✅ HostPath volume mounts
- ✅ Host port bindings
- ✅ Privilege escalation (`allowPrivilegeEscalation: true`)
- ✅ Dangerous capabilities (NET_RAW, SYS_ADMIN, etc.)
- ✅ Running as root (in restricted mode)

### Compliance Standards

This configuration helps meet:
- ✅ CIS Kubernetes Benchmark Section 5.2
- ✅ NSA Kubernetes Hardening Guidance
- ✅ Azure Well-Architected Framework - Security Pillar
- ✅ Pod Security Admission baseline standards

## 📋 Prerequisites

1. **Azure Policy Add-on**: Automatically enabled on AKS clusters
2. **Azure RBAC**: Requires `Microsoft.Authorization/policyAssignments/write` permission
3. **Cluster Version**: Kubernetes 1.23 or higher

## � Test Manifests Included

This example includes 4 test manifests to validate policy enforcement:

### Compliant Examples (Will be ALLOWED)
- **[test/compliant-pod.yaml](test/compliant-pod.yaml)** - Single pod following baseline requirements
  - Runs as non-root user (UID 1000)
  - Uses unprivileged nginx image
  - Drops all capabilities
  - No privilege escalation
  - Uses allowed volume types (emptyDir, configMap)

- **[test/compliant-deployment.yaml](test/compliant-deployment.yaml)** - Production-ready deployment
  - 3 replicas with proper security contexts
  - Read-only root filesystem
  - Custom service account (not default)
  - Resource limits and health checks
  - ClusterIP service for internal access

### Non-Compliant Examples (Will be BLOCKED)
- **[test/non-compliant-pod.yaml](test/non-compliant-pod.yaml)** - Pod with multiple violations
  - ❌ Privileged container
  - ❌ Host network, PID, and IPC access
  - ❌ Runs as root
  - ❌ Dangerous capabilities (SYS_ADMIN, NET_RAW)
  - ❌ HostPath volume mount
  - ❌ Host port binding

- **[test/non-compliant-deployment.yaml](test/non-compliant-deployment.yaml)** - Deployment with violations
  - ❌ Privileged containers
  - ❌ Host namespace access
  - ❌ Docker socket mount
  - ❌ Host filesystem access

## �🚀 Deployment Steps

### 1. Configure Variables

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply configuration (policy takes ~5-10 minutes to sync)
terraform apply
```

### 3. Verify Policy Enforcement

```bash
# Check policy assignment
az policy assignment list --resource-group <resource-group-name>

# Wait for policies to sync (5-10 minutes)
kubectl get pods -n gatekeeper-system

# Verify constraint templates are loaded
kubectl get constrainttemplates
```

### 4. Test with Example Manifests

#### Automated Testing (Recommended)

Run the automated test script:

```bash
./test/test-policies.sh
```

This script will:
- ✅ Verify kubectl is configured
- ✅ Check Gatekeeper/Azure Policy is running
- ✅ Test all 4 scenarios (2 compliant, 2 non-compliant)
- ✅ Display results with color-coded output
- ✅ Show current cluster resources

#### Manual Testing

If you prefer manual testing, use these commands:

#### Test Non-Compliant Pod (Should be BLOCKED)

```bash
# This will be DENIED by Azure Policy
kubectl apply -f test/non-compliant-pod.yaml
```

Expected output:
```
Error from server: admission webhook "validation.gatekeeper.sh" denied the request:
[denied by azurepolicy-container-no-privilege-xxx] Privileged container is not allowed: nginx, securityContext: {"privileged": true}
```

#### Test Compliant Pod (Should SUCCEED)

```bash
# This will be ALLOWED
kubectl apply -f test/compliant-pod.yaml

# Verify it's running
kubectl get pod compliant-nginx
kubectl logs compliant-nginx
```

#### Test Non-Compliant Deployment (Should be BLOCKED)

```bash
# This will be DENIED
kubectl apply -f test/non-compliant-deployment.yaml
```

Expected errors for violations:
- Privileged container not allowed
- Host namespaces (hostNetwork, hostPID) not allowed
- HostPath volumes not allowed
- Host port binding not allowed

#### Test Compliant Deployment (Should SUCCEED)

```bash
# This will be ALLOWED
kubectl apply -f test/compliant-deployment.yaml

# Verify deployment
kubectl get deployment compliant-app
kubectl get pods -l app=demo-app
kubectl get service compliant-app-service

# Test the service
kubectl port-forward service/compliant-app-service 8080:80
# Then visit http://localhost:8080 in your browser
```

### 5. Cleanup Test Resources

```bash
# Remove test pods and deployments
kubectl delete -f test/compliant-pod.yaml
kubectl delete -f test/compliant-deployment.yaml

# Verify cleanup
kubectl get pods
```

## 🔧 Configuration Options

### Audit Mode (Testing)

Use `effect = "audit"` to test policies without blocking deployments:

```terraform
pod_security_policy = {
  enabled = true
  level   = "baseline"
  effect  = "audit"  # Logs violations but allows deployment
}
```

View audit logs:
```bash
az policy state list \
  --resource-group <resource-group-name> \
  --query "[?complianceState=='NonCompliant']"
```

### Restricted Mode (Maximum Security)

For highly secure environments, use `restricted` level:

```terraform
pod_security_policy = {
  enabled = true
  level   = "restricted"  # Strictest pod hardening
  effect  = "deny"
}
```

Additional restrictions:
- Must run as non-root
- Must drop ALL capabilities
- No privilege escalation
- Limited volume types (configMap, secret, emptyDir, etc.)

### Namespace Exclusions

Exclude specific namespaces (use sparingly):

```terraform
pod_security_policy = {
  enabled             = true
  level               = "baseline"
  effect              = "deny"
  excluded_namespaces = [
    "monitoring",      # Custom monitoring tools
    "logging",         # Logging agents
    "cert-manager"     # Certificate management
  ]
}
```

**Note**: System namespaces (kube-system, gatekeeper-system, azure-arc) are automatically excluded.

## 📊 Monitoring and Compliance

### View Policy Status

```bash
# Check policy assignment details
terraform output pod_security_policy_status

# View policy compliance in Azure
az policy state summarize \
  --resource-group <resource-group-name>
```

### Common Non-Compliance Issues

| Issue | Solution |
|-------|----------|
| Pod uses `privileged: true` | Remove or set to `false` |
| Pod mounts hostPath | Use PersistentVolume or emptyDir |
| Pod uses hostPort | Use Service with LoadBalancer or Ingress |
| Pod runs as root | Set `runAsNonRoot: true` and `runAsUser: 1000` |
| Container has NET_RAW | Drop ALL capabilities and add specific ones |

## 🎯 Production Recommendations

1. **Start with Audit Mode**
   ```terraform
   effect = "audit"  # Test for 1-2 weeks
   ```

2. **Review Audit Logs**
   ```bash
   az policy state list --filter "complianceState eq 'NonCompliant'"
   ```

3. **Fix Non-Compliant Workloads**
   - Update pod specifications
   - Add securityContext settings
   - Use non-root container images

4. **Enable Deny Mode**
   ```terraform
   effect = "deny"  # Block non-compliant deployments
   ```

5. **Monitor Continuously**
   - Set up Azure Monitor alerts for policy violations
   - Regular compliance reviews
   - Update exclusions as needed

## 🔗 References

- [Azure Policy for Kubernetes](https://learn.microsoft.com/azure/aks/use-azure-policy)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)

## ⚠️ Important Notes

1. **Policy Sync Delay**: Takes 5-10 minutes for policies to sync to cluster
2. **Existing Workloads**: Not affected by policy changes (only new deployments)
3. **System Workloads**: Azure system pods are automatically excluded
4. **Breaking Changes**: Test thoroughly before switching to `deny` mode

## 🆘 Troubleshooting

### Policy Not Working

```bash
# Check Azure Policy Add-on status
kubectl get pods -n gatekeeper-system

# Verify policy assignment
az policy assignment show \
  --name <assignment-name> \
  --scope <resource-group-id>
```

### Deployment Blocked Unexpectedly

```bash
# Check specific pod requirements
kubectl describe replicaset <replicaset-name>

# Review policy details
az policy definition show \
  --name <policy-definition-id>
```

### Need to Bypass Policy Temporarily

```bash
# Option 1: Add namespace to exclusions (in terraform.tfvars)
# Option 2: Create a separate namespace and exclude it
kubectl create namespace temp-bypass

# Update policy exclusions
terraform apply -var 'pod_security_policy.excluded_namespaces=["temp-bypass"]'
```
