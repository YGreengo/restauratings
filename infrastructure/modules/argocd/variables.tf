variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "service_type" {
  description = "Kubernetes service type for ArgoCD server"
  type        = string
  default     = "ClusterIP"
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be ClusterIP, NodePort, or LoadBalancer."
  }
}

variable "repositories" {
  description = "List of Git repositories to configure in ArgoCD"
  type = list(object({
    name                 = string
    url                  = string
    type                 = string 
    username             = optional(string, "")
    password             = optional(string, "")
    ssh_private_key_path = optional(string, "")
  }))
  default = []
}

variable "applications" {
  description = "List of ArgoCD applications to create"
  type = list(object({
    name                 = string
    project              = optional(string, "default")
    repo_url            = string
    target_revision     = optional(string, "HEAD")
    path                = optional(string, ".")
    destination_namespace = string
    create_namespace    = optional(bool, true)
    auto_sync           = optional(bool, false)
    auto_prune          = optional(bool, false)
    self_heal           = optional(bool, false)
    sync_options        = optional(list(string), ["CreateNamespace=true"])
    helm_values         = optional(list(string), null)
  }))
  default = []
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default     = {}
}