# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a multi-component portfolio project showcasing a Spotify statistics application with complete infrastructure-as-code, GitOps deployment, and CI/CD pipeline. The project demonstrates full-stack development with cloud-native architecture on AWS.

**Technology Stack:**
- **Application**: FastAPI (Python) with MongoDB, containerized with Docker
- **Infrastructure**: Terraform modules for AWS EKS cluster provisioning
- **Deployment**: GitOps with ArgoCD and Helm charts
- **CI/CD**: Jenkins pipeline with automated testing and ECR deployment

## Repository Structure

```
/
├── main/                    # FastAPI Spotify application source code
├── infra/                   # Terraform infrastructure-as-code
├── gitops/                  # Kubernetes manifests and Helm charts
└── CLAUDE.md               # This file
```

## Common Development Commands

### Application Development (main/)
```bash
# Local development
cd main && python main.py

# Run tests
cd main/tests && bash test.sh
TEST_TYPE=unit bash main/tests/test.sh
TEST_TYPE=integration bash main/tests/test.sh
TEST_TYPE=all bash main/tests/test.sh

# Docker development
cd main && docker build -t spotify_app .
cd main && docker-compose up
```

### Infrastructure Management (infra/)
```bash
# Terraform operations
cd infra && terraform init
cd infra && terraform plan
cd infra && terraform apply
cd infra && terraform destroy

# Configure kubectl access
aws eks update-kubeconfig --region us-west-2 --name spotify-app-cluster
```

### GitOps Deployment (gitops/)
```bash
# Local Kind cluster
cd gitops && kind create cluster --config kind.conf

# Helm operations
cd gitops && helm dependency update ./spotify-stat-helm
cd gitops && helm install my-app ./spotify-stat-helm
cd gitops && helm lint ./spotify-stat-helm

# Application access
kubectl port-forward service/spotify-stats-app-service 8000:80
```

## Architecture Overview

**Three-Layer Architecture:**

1. **Application Layer** (`main/`):
   - FastAPI web application with Spotify OAuth integration
   - MongoDB for user data and analytics storage
   - Docker containerization with nginx reverse proxy
   - Comprehensive test suite with unit and integration tests

2. **Infrastructure Layer** (`infra/`):
   - Modular Terraform configuration for AWS EKS
   - Multi-AZ deployment across multiple availability zones
   - VPC with public/private subnets and NAT gateways
   - Security groups and IAM roles for cluster access

3. **Deployment Layer** (`gitops/`):
   - Helm charts with MongoDB dependency management
   - ArgoCD for continuous deployment
   - Kind configuration for local development
   - Environment-specific value overrides

## Key Configuration Details

**Environment Variables (Application):**
- `SPOTIFY_CLIENT_ID`, `SPOTIFY_CLIENT_SECRET`, `SPOTIFY_REDIRECT_URI`
- `MONGO_URL` (defaults to `mongodb://mongodb:27017/`)
- `SECRET_KEY` for session management

**Infrastructure Configuration:**
- **Region**: us-west-2 (configurable)
- **Cluster**: spotify-app-cluster (Kubernetes 1.27)
- **Node Type**: t3a.medium (min: 1, desired: 2, max: 3)
- **ECR Registry**: 123456789012.dkr.ecr.us-west-2.amazonaws.com

**Application Endpoints:**
- `/login` - Spotify OAuth initiation
- `/callback` - OAuth callback handler
- `/user/top_tracks` - User's top tracks API
- `/user/top_artists` - User's top artists API
- `/metrics` - Application metrics

## CI/CD Pipeline

The Jenkins pipeline (`main/Jenkinsfile`) includes:
- **Build**: Docker image creation and tagging
- **Test**: Unit and integration tests with MongoDB
- **Push**: ECR deployment with semantic versioning
- **Notify**: Slack integration and GitHub status updates

Pipeline stages run automatically on feature branches and main branch, with production deployment only on main.

## Local Development Setup

1. **Application**: `cd main && docker-compose up` (requires Spotify API credentials)
2. **Infrastructure**: Use existing EKS cluster or provision with Terraform
3. **GitOps**: `kind create cluster --config gitops/kind.conf` for local K8s testing

**Required Dependencies:**
- Docker and Docker Compose
- AWS CLI with configured credentials
- kubectl and helm
- Python 3.x with pip (for local development)
- terraform (for infrastructure changes)

## Testing Strategy

- **Unit Tests**: Core application logic with mocked dependencies
- **Integration Tests**: Full stack testing with MongoDB container
- **Pipeline Tests**: Automated testing in Docker containers within Jenkins
- **Test Command**: `bash tests/test.sh` with support for different test types via `TEST_TYPE` environment variable