# =====================
# argocd/variables.tf
# =====================

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_ca_data" {
  description = "EKS cluster certificate authority data"
  type        = string
}

variable "argocd_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "8.2.2"
}

variable "domain_name" {
  description = "Domain name for ArgoCD (optional)"
  type        = string
  default     = ""
}

variable "gitops_repo_url" {
  description = "GitOps repository HTTPS URL for ArgoCD applications"
  type        = string
}

variable "gitops_repo_ssh_url" {
  description = "GitOps repository SSH URL for ArgoCD applications"
  type        = string
}

variable "gitops_repo_path" {
  description = "Path in GitOps repository containing applications"
  type        = string
  default     = "applications"
}

variable "gitops_repo_branch" {
  description = "Branch to track in GitOps repository"
  type        = string
  default     = "main"
}

variable "argocd_ssh_private_key" {
  description = "SSH private key for GitOps repository access"
  type        = string
  sensitive   = true
}

# Note: app_namespace moved to main variables.tf since it's used by secret.tf
# Spotify credentials are now managed via AWS Secrets Manager

