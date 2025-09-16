#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if required tools are installed
    for tool in terraform kubectl aws; do
        if ! command -v $tool &> /dev/null; then
            log_error "$tool is not installed or not in PATH"
            exit 1
        fi
    done
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Check if AWS secrets exist
check_aws_secrets() {
    log_info "Checking AWS Secrets Manager..."
    
    local spotify_secret="demo/spotify/secret"
    local ssh_secret="demo/argocd/ssh-key"
    local aws_region="us-west-2"
    
    # Check Spotify secret
    if ! aws secretsmanager describe-secret --secret-id "$spotify_secret" --region "$aws_region" &>/dev/null; then
        log_error "AWS secret '$spotify_secret' not found in region '$aws_region'"
        log_error "Please create the secret first. See AWS_SECRETS_SETUP.md for instructions."
        exit 1
    fi
    
    # Check SSH secret
    if ! aws secretsmanager describe-secret --secret-id "$ssh_secret" --region "$aws_region" &>/dev/null; then
        log_error "AWS secret '$ssh_secret' not found in region '$aws_region'"
        log_error "Please create the SSH key secret first. See SSH_SETUP.md for instructions."
        exit 1
    fi
    
    log_success "All AWS secrets found and accessible"
}

# Deploy infrastructure in single step
deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log_info "Planning deployment..."
    terraform plan -out=tfplan
    
    # Ask for confirmation
    echo
    read -p "Do you want to apply the infrastructure changes? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Deployment cancelled"
        rm -f tfplan
        exit 0
    fi
    
    # Apply deployment
    log_info "Applying deployment..."
    terraform apply tfplan
    
    # Clean up
    rm -f tfplan
    
    log_success "Infrastructure deployment completed"
}

# Configure kubectl
configure_kubectl() {
    log_info "Configuring kubectl access to EKS cluster..."
    
    local cluster_name=$(terraform output -raw cluster_name 2>/dev/null || echo "saar-spotify-cluster")
    local aws_region=$(terraform output -raw aws_region 2>/dev/null || echo "us-west-2")
    
    aws eks update-kubeconfig --region $aws_region --name $cluster_name
    
    log_success "kubectl configured for cluster: $cluster_name"
}

# Wait for ArgoCD to be ready
wait_for_argocd() {
    log_info "Waiting for ArgoCD to be ready..."
    
    # Wait for ArgoCD pods to be ready
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-application-controller -n argocd --timeout=300s
    
    log_success "ArgoCD is ready"
}

# Get ArgoCD admin password
get_argocd_password() {
    log_info "Retrieving ArgoCD admin password..."
    
    local password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d 2>/dev/null || echo "")
    
    if [[ -n "$password" ]]; then
        echo
        log_success "ArgoCD Admin Credentials:"
        echo "Username: admin"
        echo "Password: $password"
        echo
        log_info "To access ArgoCD UI:"
        echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
        echo "Then open: https://localhost:8080"
    else
        log_warning "Could not retrieve ArgoCD password. It may not be ready yet."
    fi
}

# Check application status
check_applications() {
    log_info "Checking ArgoCD application status..."
    
    echo
    kubectl get applications -n argocd -o wide 2>/dev/null || log_warning "No applications found yet"
    echo
}

# Main execution
main() {
    echo "======================================"
    echo "  Spotify Stats Infrastructure Deploy"
    echo "======================================"
    echo
    
    check_prerequisites
    check_aws_secrets
    deploy_infrastructure
    configure_kubectl
    wait_for_argocd
    get_argocd_password
    check_applications
    
    echo
    log_success "Deployment completed successfully!"
    echo
    log_info "Next steps:"
    echo "1. Access ArgoCD UI using the credentials above"
    echo "2. Verify SSH connection to GitOps repository in ArgoCD"
    echo "3. Check that app-of-apps application is syncing successfully"
    echo "4. Monitor application deployment in ArgoCD"
    echo "5. Access your Spotify app once deployed"
    echo
    log_info "Troubleshooting:"
    echo "- SSH issues: See SSH_SETUP.md for troubleshooting"
    echo "- Secret issues: See AWS_SECRETS_SETUP.md for configuration"
}

# Run main function
main "$@"