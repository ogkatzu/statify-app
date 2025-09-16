# ==========================================
# network/variables.tf
# ==========================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 2
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "private_subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for private subnets"
  type        = number
  default     = 8
}

variable "public_subnet_newbits" {
  description = "Number of additional bits to extend the VPC CIDR for public subnets"
  type        = number
  default     = 8
}

variable "private_subnet_netnum_offset" {
  description = "Starting netnum for private subnets (0-based)"
  type        = number
  default     = 0
}

variable "public_subnet_netnum_offset" {
  description = "Starting netnum for public subnets (0-based)"
  type        = number
  default     = 100
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}
