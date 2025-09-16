# ==========================================
# argocd/main.tf - Dedicated ArgoCD Module
# ==========================================

# ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# ArgoCD Helm release
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = var.argocd_version

  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        config = {
          "application.instanceLabelKey" = "argocd.argoproj.io/instance"
        }
      }
      configs = {
        params = {
          "application.namespaces" = "*"
        }
      }
    })
  ]
  depends_on = [kubernetes_namespace.argocd]
}

# Note: Application namespace and secrets are now managed in secret.tf
# This ensures secrets are pulled from AWS Secrets Manager

# ArgoCD Repository SSH secret
resource "kubernetes_secret" "argocd_repo_ssh_key" {
  metadata {
    name      = "gitops-repo-ssh"
    namespace = kubernetes_namespace.argocd.metadata[0].name
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = var.gitops_repo_ssh_url
    sshPrivateKey = var.argocd_ssh_private_key
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace.argocd]
}

# ArgoCD Application for GitOps repository
resource "kubectl_manifest" "argocd_app_of_apps" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "app-of-apps"
      namespace = "argocd"
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.gitops_repo_ssh_url
        targetRevision = var.gitops_repo_branch
        path           = var.gitops_repo_path
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argocd"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })

  depends_on = [
    helm_release.argocd
  ]
}