# Pod Security Standards - Quick Testing Guide

This directory contains test manifests to validate Azure Policy enforcement of Pod Security Standards.

## 🧪 Test Files

| File | Type | Expected Result | Purpose |
|------|------|----------------|---------|
| `test/compliant-pod.yaml` | Pod | ✅ ALLOWED | Single pod following all baseline requirements |
| `test/compliant-deployment.yaml` | Deployment | ✅ ALLOWED | Production-ready deployment with 3 replicas |
| `test/non-compliant-pod.yaml` | Pod | ❌ BLOCKED | Pod with privileged access and host namespace violations |
| `test/non-compliant-deployment.yaml` | Deployment | ❌ BLOCKED | Deployment with multiple security violations |

## 🚀 Quick Test Commands

### Before Testing
```bash
# Deploy the AKS cluster with Pod Security Standards
terraform apply

# Configure kubectl
az aks get-credentials --resource-group rg-pod-security-demo --name pod-security-demo

# Wait for policies to sync (5-10 minutes)
kubectl get pods -n gatekeeper-system -w

# Verify constraint templates are loaded
kubectl get constrainttemplates
```

### Test 1: Non-Compliant Pod (Should Fail)
```bash
kubectl apply -f test/non-compliant-pod.yaml
# Expected: Error with message about privileged container not allowed
```

### Test 2: Compliant Pod (Should Succeed)
```bash
kubectl apply -f test/compliant-pod.yaml
kubectl get pod compliant-nginx
kubectl logs compliant-nginx
```

### Test 3: Non-Compliant Deployment (Should Fail)
```bash
kubectl apply -f test/non-compliant-deployment.yaml
# Expected: Multiple errors about security violations
```

### Test 4: Compliant Deployment (Should Succeed)
```bash
kubectl apply -f compliant-deployment.yaml
kubectl get deployment compliant-app
kubectl get pods -l app=demo-app
kubectl get svc compliant-app-service

# Test the service
kubectl port-forward service/compliant-app-service 8080:80
# Visit http://localhost:8080
```

## 🔍 Troubleshooting

### Policies Not Enforcing

Check if policies have synced:
```bash
# View Gatekeeper pods
kubectl get pods -n gatekeeper-system

# Check constraint templates
kubectl get constrainttemplates

# View specific constraint
kubectl get k8sazurev3noprivilege
```

### Policy Taking Too Long to Sync

Policies can take 5-10 minutes to propagate:
```bash
# Check Azure Policy assignment
az policy assignment list --resource-group rg-pod-security-demo

# Check policy state
az policy state list --resource-group rg-pod-security-demo
```

### Pod Blocked Unexpectedly

View the specific constraint violation:
```bash
# Get pod events
kubectl describe pod <pod-name>

# Check recent events
kubectl get events --sort-by='.lastTimestamp'
```

## 📊 Policy Violation Examples

### Common Violations and Fixes

| Violation | Error Message | Fix |
|-----------|---------------|-----|
| Privileged container | `Privileged container is not allowed` | Remove `privileged: true` from securityContext |
| Host namespace | `Host network is not allowed` | Remove `hostNetwork: true` |
| Root user | `Running as root is not allowed` (restricted) | Set `runAsNonRoot: true` and `runAsUser: 1000` |
| HostPath volume | `HostPath volumes are not allowed` | Use emptyDir, configMap, or PersistentVolume |
| Host port | `Host ports are not allowed` | Remove `hostPort`, use Service with LoadBalancer |
| Privilege escalation | `Privilege escalation is not allowed` (restricted) | Set `allowPrivilegeEscalation: false` |
| Dangerous capabilities | `Capability SYS_ADMIN is not allowed` | Drop ALL capabilities: `drop: ["ALL"]` |

## 🎯 Baseline vs Restricted Policies

### Baseline (Default in examples)
**Blocks:**
- Privileged containers
- Host namespace sharing (hostNetwork, hostPID, hostIPC)
- HostPath volumes
- Host port bindings
- Dangerous capabilities

**Allows:**
- Running as root (not recommended)
- Most common volume types
- Most capabilities (unless specifically dangerous)

### Restricted (Maximum Security)
**Additional requirements:**
- MUST run as non-root
- MUST drop ALL capabilities
- MUST prevent privilege escalation
- Limited volume types only (configMap, secret, emptyDir, etc.)
- Seccomp profile must be RuntimeDefault or Localhost

## 🔄 Cleanup

```bash
# Delete test resources
kubectl delete -f compliant-pod.yaml
kubectl delete -f compliant-deployment.yaml

# If you deployed non-compliant resources to excluded namespaces
kubectl delete namespace test-namespace

# Verify cleanup
kubectl get pods --all-namespaces
```

## 📚 References

- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Azure Policy for AKS](https://learn.microsoft.com/azure/aks/use-azure-policy)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NSA Kubernetes Hardening Guide](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)

## 💡 Pro Tips

1. **Start with Audit Mode**: Test with `effect = "audit"` first to identify violations without blocking deployments
2. **Check Logs Regularly**: Monitor `kubectl get events` for policy violations
3. **Use Excluded Namespaces Sparingly**: Only exclude namespaces that truly need privileged access
4. **Document Exceptions**: Maintain a list of excluded namespaces and why they need exclusions
5. **Transition to Deny Mode**: After testing, switch to `effect = "deny"` for production enforcement
6. **Consider Restricted Mode**: For high-security environments, use `level = "restricted"`
