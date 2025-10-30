# variables.tf - CORRECTED VERSION
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "owner" {
  description = "Owner tag"
  type        = string
  default     = "yarden.green"
}

variable "bootcamp" {
  description = "Bootcamp tag"
  type        = string
  default     = "BC25"
}

variable "expiration_date" {
  description = "Expiration date tag"
  type        = string
  default     = "10-09-25"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "yarden-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Number of subnets to create"
  type        = number
  default     = 2
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "yarden-node-group"
}

variable "node_instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2_x86_64"
}

variable "node_capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 20
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "instance_ssh_key" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
  default     = "Yarden-ImmersionDay"
}

variable "instance_ami" {
  description = "AMI ID for instances"
  type        = string
  default     = "ami-0f918f7e67a3323f0"
}

# ArgoCD Configuration Variables
variable "argocd_namespace" {
  description = "Kubernetes namespace for ArgoCD"
  type        = string
  default     = "argocd"
}

variable "argocd_service_type" {
  description = "Kubernetes service type for ArgoCD server"
  type        = string
  default     = "ClusterIP"
}

variable "argocd_repositories" {
  description = "List of Git repositories to configure in ArgoCD"
  type = list(object({
    name                 = string
    url                  = string
    type                 = string # "https" or "ssh"
    username             = optional(string, "")
    password             = optional(string, "")
    ssh_private_key_path = optional(string, "")
  }))
  default = []
}

variable "argocd_applications" {
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