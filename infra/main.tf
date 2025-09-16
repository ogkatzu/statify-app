# =============================================================================
# main.tf - Main Configuration
# =============================================================================

# Data source to fetch ArgoCD SSH private key from AWS Secrets Manager
data "aws_secretsmanager_secret" "argocd_ssh_key" {
  name = "saar/argocd/ssh-key"
}

data "aws_secretsmanager_secret_version" "argocd_ssh_key" {
  secret_id = data.aws_secretsmanager_secret.argocd_ssh_key.id
}

module "network" {
  source = "./modules/network"

  vpc_cidr                     = var.vpc_cidr
  availability_zones           = var.availability_zones
  private_subnet_count         = var.private_subnet_count
  public_subnet_count          = var.public_subnet_count
  private_subnet_newbits       = var.private_subnet_newbits
  public_subnet_newbits        = var.public_subnet_newbits
  private_subnet_netnum_offset = var.private_subnet_netnum_offset
  public_subnet_netnum_offset  = var.public_subnet_netnum_offset
  cluster_name                 = var.cluster_name
  environment                  = var.environment
  project_name                 = var.project_name
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  cluster_version    = var.cluster_version
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  cluster_security_group_id = module.network.cluster_security_group_id
  node_security_group_id    = module.network.node_security_group_id

  node_instance_type    = var.node_instance_type
  node_desired_capacity = var.node_desired_capacity
  node_max_capacity     = var.node_max_capacity
  node_min_capacity     = var.node_min_capacity

  environment  = var.environment
  project_name = var.project_name
}

module "argocd" {
  source = "./modules/argocd"

  cluster_name     = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_ca_data  = module.eks.cluster_certificate_authority_data

  # ArgoCD configuration
  argocd_version = "6.7.3"

  # GitOps configuration
  gitops_repo_url        = var.gitops_repo_url
  gitops_repo_ssh_url    = var.gitops_repo_ssh_url
  gitops_repo_path       = var.gitops_repo_path
  gitops_repo_branch     = var.gitops_repo_branch
  argocd_ssh_private_key = data.aws_secretsmanager_secret_version.argocd_ssh_key.secret_string

  # Dependencies
  depends_on = [
    module.eks
  ]
}