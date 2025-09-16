variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "saar-spotify-app"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "saar-spotify-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.27"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "private_subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for private subnets"
  type        = number
  default     = 8
}

variable "private_subnet_netnum_offset" {
  description = "Starting netnum for private subnets (0-based)"
  type        = number
  default     = 0
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "public_subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for public subnets"
  type        = number
  default     = 8
}

variable "public_subnet_netnum_offset" {
  description = "Starting netnum for public subnets (0-based)"
  type        = number
  default     = 100
}

variable "node_instance_type" {
  description = "EC2 instance type for the node group"
  type        = string
  default     = "t3a.medium"
}

variable "node_desired_capacity" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_max_capacity" {
  description = "Maximum number of nodes"
  type        = number
  default     = 3
}

variable "node_min_capacity" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "app_namespace" {
  description = "Namespace for the application"
  type        = string
  default     = "spotify-app"
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

# Note: Spotify credentials are now managed via AWS Secrets Manager
# See secret.tf for implementation
