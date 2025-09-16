#!/bin/bash

# Infrastructure Destruction Script
# This script handles the proper order of resource destruction to avoid dependency issues

set -e

echo "🔥 Starting infrastructure destruction..."
echo "⚠️  This will destroy all AWS resources created by this Terraform configuration!"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    echo "❌ Destruction cancelled."
    exit 0
fi

echo "📋 Destroying resources in proper order..."

# Step 1: Clean up ArgoCD finalizers and destroy namespace
echo "🔧 Step 1: Cleaning up ArgoCD finalizers..."
kubectl get Application -A -o name | xargs kubectl patch -p '{"metadata":{"finalizers":null}}' --type=merge -n argocd 2>/dev/null || true
kubectl patch application kibana -n argocd -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
# kubectl patch applications -n argocd --all --type=merge -p '{"metadata":{"finalizers":[]}}' 2>/dev/null || true
kubectl delete applications -n argocd --all --timeout=60s 2>/dev/null || true
echo "🔧 Step 1b: Destroying ArgoCD resources..."
terraform destroy -target=module.argocd.kubernetes_namespace.argocd -auto-approve || true

# Step 2: Destroy EKS resources (they have public IPs)
echo "🔧 Step 2: Destroying EKS node group and cluster..."
terraform destroy -target=module.eks.aws_eks_node_group.main -auto-approve || true
terraform destroy -target=module.eks.aws_eks_addon.coredns -auto-approve || true
terraform destroy -target=module.eks.aws_eks_addon.ebs_csi -auto-approve || true
terraform destroy -target=module.eks.aws_eks_addon.kube_proxy -auto-approve || true
terraform destroy -target=module.eks.aws_eks_addon.vpc_cni -auto-approve || true
terraform destroy -target=module.eks.aws_eks_cluster.main -auto-approve || true

# Step 3: Clean up ingress controller resources (ELBs, Security Groups)
echo "🔧 Step 3: Cleaning up ingress controller ELBs and security groups..."
VPC_ID=$(terraform output -raw vpc_id 2>/dev/null || echo "vpc-0ebda1aabec5699a0")

# Delete all load balancers in the VPC
aws elbv2 describe-load-balancers --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text | xargs -I {} aws elbv2 delete-load-balancer --load-balancer-arn {} 2>/dev/null || true
aws elb describe-load-balancers --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text | xargs -I {} aws elb delete-load-balancer --load-balancer-name {} 2>/dev/null || true

# Delete security groups created by ingress controller (usually tagged with kubernetes.io/cluster)
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag-key,Values=kubernetes.io/cluster*" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text | xargs -I {} aws ec2 delete-security-group --group-id {} 2>/dev/null || true

# Step 4: Wait for AWS to release public IPs and clean up resources
echo "⏳ Waiting for AWS to release public IP addresses and clean up ELBs..."
sleep 45

# Step 5: Destroy network route tables to break IGW dependencies
echo "🔧 Step 5: Destroying route tables..."
terraform destroy -target=module.network.aws_route_table.public -auto-approve || true
terraform destroy -target=module.network.aws_route_table.private -auto-approve || true

# Step 6: Destroy route table associations
echo "🔧 Step 6: Destroying route table associations..."
terraform destroy -target=module.network.aws_route_table_association.public -auto-approve || true
terraform destroy -target=module.network.aws_route_table_association.private -auto-approve || true

# Step 7: Wait a moment for AWS to process
echo "⏳ Waiting for AWS to process network deletions..."
sleep 15

# Step 8: Destroy everything else
echo "🔧 Step 8: Destroying remaining infrastructure..."
terraform destroy -auto-approve

echo "✅ Infrastructure destruction completed!"
echo "💡 Don't forget to check the AWS console to verify all resources were deleted."