# Restauratings Infrastructure (EKS + ArgoCD)

This repository provides the **Terraform code** to provision an **Amazon EKS cluster** with **ArgoCD** for GitOps workflows.

---

## 🌐 Architecture

- **EKS Cluster**: Kubernetes 1.28 on AWS, provisioned in **private subnets** for enhanced security
- **VPC**: Custom VPC spanning **2 Availability Zones**, with public and private subnets
- **NAT Gateway**: Provides internet access for private subnets (for pulling container images, etc.)
- **Node Group**: 3x `t3.medium` EC2 instances running in the private subnets
- **ArgoCD**: GitOps controller deployed in the cluster and exposed via port forwarding
- **GitLab SSH Integration**: Pre-configured access to your private GitOps repo via SSH key

---

## ✅ Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.0
- `kubectl`
- SSH key at `~/.ssh/id_ed25519` with access to GitLab

---

## 🚀 Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review changes
terraform plan

# Apply infrastructure
terraform apply
```

---

## 🔑 Access ArgoCD

```bash
# Get admin password (Terraform output)
terraform output -raw argocd_admin_password

# Or manually from the cluster
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo

# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

- **ArgoCD UI**: [https://localhost:8080](https://localhost:8080)
- **Username**: `admin`
- **Password**: (see above)

---

## 📜 Configure kubectl

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name yarden-eks-cluster
```

---

## 📁 Repository Structure

```
.
├── main.tf                 # Root Terraform config
├── variables.tf            # Input variables
├── outputs.tf              # Output values
├── terraform.tfvars        # Environment-specific variables
└── modules/
    ├── network/            # VPC, subnets, routing
    ├── compute/            # EKS cluster + node groups
    └── argocd/             # ArgoCD installation
```

---

## ⚖️ Configuration

Main values in `terraform.tfvars`:

```hcl
region           = "ap-south-1"
cluster_name     = "yarden-eks-cluster"
gitops_repo_ssh  = "git@gitlab.com:greengo-jenkins/restauratings-gitops.git"
```

---

## 💡 GitOps Workflow

- **GitOps Repo**: [restauratings-gitops](https://gitlab.com/greengo-jenkins/restauratings-gitops)
- **Apps**: Managed via ArgoCD App-of-Apps pattern
- **Sync**: ArgoCD automatically syncs cluster state with Git

Once the infrastructure is ready, follow the GitOps repo instructions to deploy:
- Ingress, monitoring, and logging stacks
- Sealed secrets, cert-manager, and the main application

---

## 🗑️ Cleanup

```bash
terraform destroy
```

---

## 📊 Outputs

```bash
terraform output                          # View all outputs
terraform output -raw argocd_admin_password
terraform output kubectl_port_forward_command
```

---

## ⚠️ Notes

- This setup uses **SSH authentication** for GitLab.
- Ensure your SSH key has access to the GitOps repository.

