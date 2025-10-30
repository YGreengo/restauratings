# outputs.tf - Updated with ArgoCD outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.network.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.network.public_subnet_ids
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.compute.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.compute.cluster_security_group_id
}

output "cluster_iam_role_name" {
  description = "IAM role name associated with EKS cluster"
  value       = module.compute.cluster_iam_role_name
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.compute.cluster_certificate_authority_data
}

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.compute.cluster_name
}

output "node_group_arn" {
  description = "Amazon Resource Name (ARN) of the EKS Node Group"
  value       = module.compute.node_group_arn
}

output "kubeconfig_command" {
  description = "Command to update kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}"
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Identity Provider"
  value       = module.compute.oidc_provider_arn
}

# ArgoCD Outputs
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = module.argocd.argocd_namespace
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = module.argocd.argocd_admin_password
  sensitive   = true
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = module.argocd.argocd_admin_password_command
}

output "argocd_server_url" {
  description = "ArgoCD server URL"
  value       = module.argocd.argocd_server_url
}

output "kubectl_port_forward_command" {
  description = "Command to port-forward to ArgoCD server"
  value       = module.argocd.kubectl_port_forward_command
}

output "argocd_login_command" {
  description = "Command to login to ArgoCD CLI"
  value       = module.argocd.argocd_login_command
  sensitive   = true
}

output "repository_secrets" {
  description = "Names of created repository secrets"
  value       = module.argocd.repository_secrets
}