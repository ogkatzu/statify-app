# ===========================
# Outputs for ArgoCD Access
# ===========================

output "namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service_name" {
  description = "ArgoCD server service name"
  value       = "${helm_release.argocd.name}-server"
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
}

output "argocd_server_url" {
  description = "ArgoCD server URL (only accessible via port forwarding)"
  value       = "https://localhost:8080 (after running port-forward command)"
}

output "kubectl_port_forward_command" {
  description = "Command to access ArgoCD via port forwarding"
  value       = "kubectl port-forward svc/${helm_release.argocd.name}-server -n ${kubernetes_namespace.argocd.metadata[0].name} 8080:443"
}