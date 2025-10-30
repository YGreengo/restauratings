output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service_name" {
  description = "Name of the ArgoCD server service"
  value       = "argocd-server"
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = local.password_value
  sensitive   = true
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = "kubectl -n ${var.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d; echo"
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = "http://localhost:8080 (use kubectl port-forward)"
}

output "kubectl_port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443"
}

output "repository_secrets" {
  description = "Names of created repository secrets"
  value       = [for secret in kubernetes_secret.repository : secret.metadata[0].name]
}

output "applications" {
  description = "Names of created ArgoCD applications"
  value       = [for app in kubernetes_manifest.applications : app.manifest.metadata.name]
}

output "argocd_login_command" {
  description = "Command to login to ArgoCD CLI"
  value       = local.password_exists ? "argocd login localhost:8080 --username admin --password '${local.password_value}' --insecure" : "Password not available - use: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
  sensitive   = true
}