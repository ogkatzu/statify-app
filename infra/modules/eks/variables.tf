# ===================
# eks/variables.tf
# ===================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for the cluster"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID for the nodes"
  type        = string
}

variable "node_instance_type" {
  description = "EC2 instance type for the node group"
  type        = string
}

variable "node_desired_capacity" {
  description = "Desired number of nodes"
  type        = number
}

variable "node_max_capacity" {
  description = "Maximum number of nodes"
  type        = number
}

variable "node_min_capacity" {
  description = "Minimum number of nodes"
  type        = number
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}
