terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# ArgoCD Namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      name = var.argocd_namespace
    }
  }
}

# ArgoCD Installation via kubectl
resource "null_resource" "install_argocd_kubectl" {
  provisioner "local-exec" {
    command = <<EOT
      echo "Configuring kubectl for EKS cluster..."
      aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}
      
      echo "Testing cluster connectivity..."
      kubectl get nodes
      
      echo "Installing ArgoCD via kubectl..."
      kubectl apply -n ${var.argocd_namespace} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --validate=false
      
      echo "Waiting for ArgoCD deployments to be ready..."
      kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n ${var.argocd_namespace}
      kubectl wait --for=condition=available --timeout=600s deployment/argocd-repo-server -n ${var.argocd_namespace}
      
      echo "Waiting for ArgoCD application controller statefulset to be ready..."
      kubectl wait --for=jsonpath='{.status.readyReplicas}'=1 --timeout=600s statefulset/argocd-application-controller -n ${var.argocd_namespace}
      
      echo "ArgoCD installation completed successfully!"
    EOT
  }

  depends_on = [kubernetes_namespace.argocd]

  triggers = {
    namespace = var.argocd_namespace
    timestamp = timestamp()
  }
}

# Repository Secret
resource "kubernetes_secret" "repository" {
  for_each = { for repo in var.repositories : repo.name => repo }

  metadata {
    name      = "${each.value.name}-repo-secret"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = merge({
    type = "git"
    url  = each.value.url
  },
  each.value.type == "https" ? {
    username = each.value.username
    password = each.value.password
  } : {},
  each.value.type == "ssh" ? {
    sshPrivateKey = file(each.value.ssh_private_key_path)
  } : {})

  type = "Opaque"

  depends_on = [null_resource.install_argocd_kubectl]
}

# ArgoCD Applications
resource "kubernetes_manifest" "applications" {
  for_each = { for app in var.applications : app.name => app }

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = each.value.name
      namespace = var.argocd_namespace
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      project = each.value.project
      source = {
        repoURL        = each.value.repo_url
        targetRevision = each.value.target_revision
        path           = each.value.path
        helm = each.value.helm_values != null ? {
          valueFiles = each.value.helm_values
        } : null
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = each.value.destination_namespace
      }
      syncPolicy = {
        automated = each.value.auto_sync ? {
          prune    = each.value.auto_prune
          selfHeal = each.value.self_heal
        } : null
        syncOptions = each.value.sync_options
      }
    }
  }

  depends_on = [
    kubernetes_secret.repository,
    null_resource.install_argocd_kubectl
  ]
}

# Create destination namespaces if they don't exist
resource "kubernetes_namespace" "app_namespaces" {
  for_each = toset([for app in var.applications : app.destination_namespace if app.create_namespace])

  metadata {
    name = each.value
    labels = {
      "managed-by" = "argocd"
    }
  }
}

# ArgoCD initial admin password retrieval
data "kubernetes_secret" "argocd_initial_admin_secret" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.argocd_namespace
  }

  depends_on = [null_resource.install_argocd_kubectl]
}

# Check if password exists and is valid
locals {
  password_data = try(data.kubernetes_secret.argocd_initial_admin_secret.data["password"], "")
  password_exists = local.password_data != ""
  password_value = local.password_exists ? try(base64decode(local.password_data), "Password decode failed - use kubectl command") : "Password not available yet"
}

# Service for external access (if not using ClusterIP)
resource "kubernetes_service" "argocd_server_external" {
  count = var.service_type != "ClusterIP" ? 1 : 0

  metadata {
    name      = "argocd-server-external"
    namespace = var.argocd_namespace
  }

  spec {
    type = var.service_type
    port {
      port        = 80
      target_port = 8080
      protocol    = "TCP"
      name        = "server"
    }
    port {
      port        = 443
      target_port = 8080
      protocol    = "TCP"
      name        = "server-https"
    }
    selector = {
      "app.kubernetes.io/component" = "server"
      "app.kubernetes.io/name"      = "argocd-server"
      "app.kubernetes.io/part-of"   = "argocd"
    }
  }

  depends_on = [null_resource.install_argocd_kubectl]
}
