# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a comprehensive GitOps repository implementing a production-grade Spotify Stats application with full observability stack. The architecture demonstrates multi-layered GitOps with ArgoCD app-of-apps pattern, combining application deployment with infrastructure components.

**Technology Stack:**
- **Application**: Spotify Stats FastAPI (Python) with MongoDB replica set
- **GitOps**: ArgoCD with app-of-apps pattern for multi-tier deployments  
- **Infrastructure**: Nginx Ingress, Cert-Manager, Prometheus/Grafana monitoring
- **Observability**: ELK stack (Elasticsearch, Fluent Bit) for centralized logging
- **Security**: TLS termination, Let's Encrypt certificates, private ECR registry

## Architecture

**Three-Layer GitOps Architecture:**

1. **App-of-Apps Layer** (`app-of-apps.yaml`):
   - Manages infrastructure applications deployment (sync-wave: 0)
   - Coordinates application deployment after infrastructure readiness

2. **Infrastructure Layer** (`infra-apps/`):
   - Nginx Ingress Controller with metrics integration
   - Prometheus Stack for monitoring and alerting  
   - Cert-Manager for automated TLS certificate management
   - Elasticsearch and Fluent Bit for log aggregation
   - All deployed via ArgoCD Applications with external Helm repositories

3. **Application Layer** (`spotify-stat-helm/`):
   - Umbrella Helm chart managing Spotify app + MongoDB
   - Production-ready ingress with HTTPS termination
   - MongoDB replica set (3 nodes) with persistent storage
   - ECR-hosted container images with version pinning

## Repository Structure

**Current Architecture:**
```
/
├── app-of-apps.yaml                    # ArgoCD App-of-Apps root application
├── spotify-app.yaml                    # Spotify application ArgoCD config
├── infra-apps/                         # Infrastructure components
│   ├── nginx-ingress-controller.yaml   # Ingress with Prometheus metrics
│   ├── prometheus-stack.yaml           # Monitoring stack (Grafana/Prometheus)
│   ├── cert-manager.yaml               # TLS certificate automation
│   ├── elasticsearch.yaml              # Log storage backend
│   ├── fluent-bit.yaml                 # Log collection agent
│   └── values/                         # Environment-specific configurations
├── spotify-stat-helm/                  # Main Helm umbrella chart
│   ├── Chart.yaml                      # Dependencies: MongoDB + spotify-stat-app
│   ├── values.yaml                     # MongoDB replica set configuration
│   └── charts/spotify-stat-app/        # Application-specific Helm chart
│       ├── templates/                  # K8s resource templates
│       │   ├── deployment.yaml         # App deployment with ECR integration
│       │   ├── ingress.yaml            # HTTPS ingress with Let's Encrypt
│       │   ├── cluster-issuer.yaml     # Cert-Manager cluster issuer
│       │   └── service.yaml            # ClusterIP service
│       └── values.yaml                 # App config with ingress/TLS
├── kubernetes/                         # Raw manifests (reference/testing)
└── test_requests.py                    # Production endpoint testing script
```

## Common Commands

**ArgoCD Application Management:**  
```bash
# Deploy infrastructure first (app-of-apps pattern)
kubectl apply -f app-of-apps.yaml

# Deploy Spotify application
kubectl apply -f spotify-app.yaml

# Check ArgoCD application status
argocd app list
argocd app get infra-apps
argocd app get spotify-stat-app

# Force sync applications
argocd app sync infra-apps
argocd app sync spotify-stat-app
```

**Local Development with Kind:**
```bash
# Create EFK cluster (3 workers + control-plane)
kind create cluster --config kind.conf

# Deploy via Helm (local testing)
cd spotify-stat-helm
helm dependency update
helm install spotify-app . --namespace spotify-app --create-namespace

# Access application
kubectl port-forward -n spotify-app svc/spotify-stat-app-spotify-stat-app 8000:80

# Test production endpoint
python test_requests.py  # Tests https://your-domain.example.com/
```

**Helm Chart Development:**
```bash
# Update dependencies and lint
cd spotify-stat-helm
helm dependency update
helm lint .
helm lint charts/spotify-stat-app/

# Test template rendering
helm template spotify-app . --namespace spotify-app --debug
helm template test charts/spotify-stat-app/ --debug

# Validate MongoDB configuration  
helm dependency list
```

**Monitoring and Debugging:**
```bash
# Check application logs
kubectl logs -n spotify-app -l app.kubernetes.io/name=spotify-stat-app --tail=100

# MongoDB replica set status
kubectl exec -n spotify-app spotify-stat-helm-mongodb-0 -- mongosh --eval "rs.status()"

# Check ingress and certificates
kubectl get ingress -n spotify-app
kubectl get certificates -n spotify-app
kubectl describe certificaterequest -n spotify-app

# Prometheus metrics
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

**ECR Authentication (for local Kind clusters):**
```bash
# ECR login and create registry secret
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com

kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=123456789012.dkr.ecr.us-west-2.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-west-2) \
  --namespace spotify-app
```

## Application Configuration Details

**Spotify Stats Application:**
- **Runtime**: FastAPI Python application on port 8000, 3 replicas
- **Image**: ECR registry `123456789012.dkr.ecr.us-west-2.amazonaws.com/demo/spotify-app:1.0.16`
- **Resources**: 128Mi/100m requests, 256Mi/200m limits per pod
- **OAuth Flow**: Spotify API integration with redirect URI `http://127.0.0.1:8000/callback`
- **Environment Variables**: SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, SPOTIFY_REDIRECT_URI, MONGO_URL

**MongoDB Replica Set (Production-Grade):**
- **Chart Source**: Bitnami MongoDB 15.6.13 via Helm dependency
- **Architecture**: 3-node replica set with authentication enabled
- **Storage**: 8Gi persistent volumes per node (GP2 storage class)
- **Connection**: `spotify-stat-helm-mongodb:27017` service endpoint
- **Authentication**: Root user + dedicated `spotify_user` for application access

**Production Ingress & TLS:**
- **Domain**: `your-domain.example.com` with Let's Encrypt TLS certificates  
- **Ingress Class**: nginx with SSL redirect and force HTTPS
- **Cert-Manager**: Automated certificate provisioning and renewal
- **Load Balancer**: AWS LoadBalancer service type for external access

**Monitoring & Observability:**
- **Metrics**: Prometheus ServiceMonitor for nginx ingress metrics collection
- **Logging**: Fluent Bit agent for log aggregation to Elasticsearch
- **Monitoring Stack**: Grafana + Prometheus deployed in `monitoring` namespace
- **Health Checks**: Kubernetes liveness/readiness probes

## Production Deployment Architecture

**GitOps Flow (App-of-Apps Pattern):**
1. **Infrastructure Phase**: ArgoCD deploys nginx-ingress, cert-manager, prometheus-stack (sync-wave: 0)
2. **Ingress Setup**: Nginx controller with LoadBalancer service (sync-wave: 1)  
3. **Application Phase**: Spotify app deployment after infrastructure readiness
4. **Automated Sync**: Self-healing with automated pruning and sync policies

**Multi-Environment Support:**
- **Values Override**: Environment-specific configurations in `values/` directory
- **Namespace Isolation**: Dedicated namespaces (spotify-app, monitoring, ingress-nginx)
- **Secret Management**: Kubernetes secrets with ECR registry authentication
- **Version Pinning**: Explicit chart and image versions for stability

**Deployment Dependencies:**
- MongoDB must be ready before application pods start
- Cert-Manager required for TLS certificate issuance
- Nginx Ingress Controller for external traffic routing
- ECR authentication for private image pulls

## Development Workflow

**Local Testing with Kind:**
- **Cluster**: EFK cluster (efk-cluster) with 3 worker nodes + control-plane
- **Mount Points**: Host path mounts for development (see kind.conf:8-18)
- **Testing**: Use `test_requests.py` for concurrent load testing
- **Access Pattern**: Port-forward to localhost:8000 for OAuth compliance

**Troubleshooting Production Issues:**
- **Image Pull Errors**: Recreate ECR registry secret (expires every 12 hours)
- **MongoDB Connection**: Verify replica set status and authentication
- **Certificate Issues**: Check cert-manager logs and certificate resources
- **Ingress Problems**: Validate nginx controller deployment and service