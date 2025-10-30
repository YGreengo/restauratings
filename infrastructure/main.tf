terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
  
  backend "s3" {
    bucket         = "yarden-tf-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for common tags and calculations
locals {
  common_tags = {
    owner           = var.owner
    bootcamp        = var.bootcamp
    expiration_date = var.expiration_date
    Environment     = var.environment
    Project         = "EKS-Cluster"
  }
  
  # Calculate CIDR blocks dynamically based on AZs
  vpc_cidr = var.vpc_cidr
  private_subnet_cidrs = [
    for i, az in slice(data.aws_availability_zones.available.names, 0, var.subnet_count) :
    cidrsubnet(local.vpc_cidr, 8, i + 1)
  ]
  public_subnet_cidrs = [
    for i, az in slice(data.aws_availability_zones.available.names, 0, var.subnet_count) :
    cidrsubnet(local.vpc_cidr, 8, i + 101)
  ]
  availability_zones = slice(data.aws_availability_zones.available.names, 0, var.subnet_count)
}

# Network Module
module "network" {
  source = "./modules/network"
  
  vpc_cidr               = local.vpc_cidr
  private_subnet_cidrs   = local.private_subnet_cidrs
  public_subnet_cidrs    = local.public_subnet_cidrs
  availability_zones     = local.availability_zones
  cluster_name          = var.cluster_name
  
  tags = merge(local.common_tags, {
    Name = "${var.cluster_name}-network"
  })
}

# Compute Module (EKS)
module "compute" {
  source = "./modules/compute"

  aws_region = var.aws_region
  cluster_name               = var.cluster_name
  cluster_version           = var.cluster_version
  vpc_id                    = module.network.vpc_id
  vpc_cidr                  = local.vpc_cidr
  private_subnet_ids        = module.network.private_subnet_ids
  public_subnet_ids         = module.network.public_subnet_ids
  
  # Node group configuration
  node_group_name           = var.node_group_name
  node_instance_types      = var.node_instance_types
  node_ami_type           = var.node_ami_type
  node_capacity_type      = var.node_capacity_type
  node_disk_size          = var.node_disk_size
  node_desired_size       = var.node_desired_size
  node_max_size           = var.node_max_size
  node_min_size           = var.node_min_size
  instance_ssh_key        = var.instance_ssh_key
  
  tags = local.common_tags
}

# Configure Kubernetes provider after EKS cluster exists  
data "aws_eks_cluster" "cluster" {
  name       = module.compute.cluster_name
  depends_on = [module.compute]
}

data "aws_eks_cluster_auth" "cluster" {
  name       = module.compute.cluster_name  
  depends_on = [module.compute]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# ArgoCD Module
module "argocd" {
  source = "./modules/argocd"
  
  aws_region        = var.aws_region
  cluster_name      = var.cluster_name
  argocd_namespace  = var.argocd_namespace
  service_type      = var.argocd_service_type
  
  repositories = var.argocd_repositories
  applications = var.argocd_applications
  
  tags = local.common_tags
  
  depends_on = [module.compute, data.aws_eks_cluster.cluster, data.aws_eks_cluster_auth.cluster]
}