
# ========================================= #
# eks/main.tf - EKS Cluster Configuration   #
# ========================================= #

# Data sources
data "aws_partition" "current" {}

# ========================================= #
# EKS Role and attachments #                #
# ========================================= #

# This role is created with the policy to allow EKS to manage the cluster
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = {
    Name        = "${var.project_name}-cluster-role"
    Environment = var.environment
  }
}

# Attach the necessary policies to the cluster role
resource "aws_iam_role_policy_attachment" "cluster_amazon_eks_cluster_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# =========================================
# ########## EKS Cluster ###########
# =========================================

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    security_group_ids      = [var.cluster_security_group_id]
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]
  # Waiting for the role attachments to be created first
  depends_on = [
    aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy
  ]

  tags = {
    Name        = var.cluster_name
    Environment = var.environment
  }
}

# =========================================
# #### EKS Node Group Configuration ####
# =========================================

# EKS Node Group Service Role
resource "aws_iam_role" "node" {
  name = "${var.project_name}-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })

  tags = {
    Name        = "${var.project_name}-node-role"
    Environment = var.environment
  }
}
# Attach the necessary policies to the node role

# EKS worker node policies
resource "aws_iam_role_policy_attachment" "node_amazon_eks_worker_node_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

# EKS CNI policy
resource "aws_iam_role_policy_attachment" "node_amazon_eks_cni_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}

# ECR read-only policy for nodes to pull images
resource "aws_iam_role_policy_attachment" "node_amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

# EBS CSI driver policy for persistent volume provisioning
resource "aws_iam_role_policy_attachment" "node_amazon_ebs_csi_driver_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.node.name
}


# EKS Node Group configuration
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = var.node_max_capacity
    min_size     = var.node_min_capacity
  }

  update_config {
    max_unavailable = 1
  }

  instance_types = [var.node_instance_type]
  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"

  depends_on = [
    aws_iam_role_policy_attachment.node_amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.node_amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.node_amazon_ec2_container_registry_read_only,
  ]

  tags = {
    Name        = "${var.project_name}-node-group"
    Environment = var.environment
  }
}


# =========================================
# EKS Add-ons
# =========================================
# This is not mandatory but recommended for EKS clusters

# EKS Add-on VCP CNI
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = {
    Name        = "${var.cluster_name}-vpc-cni"
    Environment = var.environment
  }
}

# EKS Add-ons for CoreDNS
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = {
    Name        = "${var.cluster_name}-coredns"
    Environment = var.environment
  }
}

# EKS Add-on kube-proxy
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = {
    Name        = "${var.cluster_name}-kube-proxy"
    Environment = var.environment
  }
}

#EKS Add-on EBS CSI Driver
resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "aws-ebs-csi-driver"

  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = {
    Name        = "${var.cluster_name}-ebs-csi"
    Environment = var.environment
  }
}

