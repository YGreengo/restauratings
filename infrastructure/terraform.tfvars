aws_region      = "ap-south-1"
owner          = "yarden.green"
bootcamp       = "BC25"
expiration_date = "10-09-25"
environment    = "production"
cluster_name   = "yarden-eks-cluster"
cluster_version = "1.28"
vpc_cidr       = "10.0.0.0/16"
subnet_count   = 2
node_group_name = "yarden-node-group"
node_instance_types = ["t3.medium"]
node_desired_size = 3
node_max_size    = 4
node_min_size    = 1
instance_ssh_key = "Yarden-ImmersionDay"
instance_ami     = "ami-0f918f7e67a3323f0"

argocd_namespace    = "argocd"
argocd_service_type = "ClusterIP" 
argocd_repositories = [
  {
    name                 = "restauratings-gitops"
    url                  = "git@gitlab.com:greengo-jenkins/restauratings-gitops.git"
    type                 = "ssh"
    ssh_private_key_path = "/home/yarden/.ssh/id_ed25519"
  }
]

argocd_applications = []

