# AKS Cluster outputs
output "cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.aks_pod_security.cluster_name
}

output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks_pod_security.cluster_id
}

output "cluster_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = module.aks_pod_security.cluster_fqdn
}

output "kube_config_command" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group rg-${var.cluster_name} --name ${var.cluster_name}"
}

# Pod Security Policy outputs
output "pod_security_policy_status" {
  description = "Status of the Pod Security Standards enforcement"
  value       = module.aks_pod_security.pod_security_policy_status
}

# Testing commands
output "test_compliant_pod" {
  description = "Command to deploy a compliant pod (should succeed)"
  value       = <<-EOT
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: compliant-nginx
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: nginx
        image: nginxinc/nginx-unprivileged:latest
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
          readOnlyRootFilesystem: false
    EOF
  EOT
}

output "test_noncompliant_pod" {
  description = "Command to deploy a non-compliant pod (should be blocked)"
  value       = <<-EOT
    kubectl apply -f - <<EOF
    apiVersion: v1
    kind: Pod
    metadata:
      name: privileged-nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        securityContext:
          privileged: true
    EOF
  EOT
}

output "check_policy_status" {
  description = "Command to check Azure Policy compliance status"
  value       = "az policy state list --resource-group rg-${var.cluster_name} --query \"[?complianceState=='NonCompliant']\" -o table"
}

output "view_gatekeeper_pods" {
  description = "Command to view Azure Policy/Gatekeeper pods"
  value       = "kubectl get pods -n gatekeeper-system"
}

# Monitoring outputs
output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.aks_monitoring.id
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = "rg-${var.cluster_name}"
}

# Next steps
output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    
    ✅ Deployment Complete! Pod Security Standards are active.
    
    📋 Next Steps:
    
    1. Configure kubectl:
       ${format("%-60s", "az aks get-credentials --resource-group rg-${var.cluster_name} --name ${var.cluster_name}")}
    
    2. Verify Azure Policy/Gatekeeper is running:
       kubectl get pods -n gatekeeper-system
    
    3. View policy constraints:
       kubectl get constrainttemplates
    
    4. Test compliant pod (should succeed):
       kubectl apply -f examples/compliant-pod.yaml
    
    5. Test non-compliant pod (should be blocked):
       kubectl apply -f examples/privileged-pod.yaml
    
    6. Check policy compliance:
       az policy state list --resource-group rg-${var.cluster_name}
    
    ⚠️  Note: Policies take 5-10 minutes to fully sync to the cluster.
    
    📊 Policy Configuration:
       - Level: ${var.pod_security_policy.level}
       - Effect: ${var.pod_security_policy.effect}
       - Status: ${var.pod_security_policy.enabled ? "Enabled" : "Disabled"}
    
    🔗 Learn More:
       - https://learn.microsoft.com/azure/aks/use-azure-policy
       - https://kubernetes.io/docs/concepts/security/pod-security-standards/
  EOT
}
