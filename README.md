# Spotify Statistics Application

A production-ready Spotify statistics web application showcasing modern cloud-native architecture with complete DevOps pipeline. This project demonstrates full-stack development from containerized application to AWS cloud deployment using GitOps principles.

## What It Does

The application connects to your Spotify account and provides personalized music analytics including:

- **Top Tracks**: Your most played songs with detailed statistics
- **Top Artists**: Your favorite artists and listening patterns  
- **Genre Analysis**: Music taste breakdown and preferences
- **Popularity Metrics**: Average popularity scores of your music
- **Historical Data**: Track your listening habits over time

### Screenshots 
![App Screenshot](app_example.png)

## General Architecture

![Architecture Overview](General_Diagram_v2.png)

## Technology Stack

### Application Layer
- **FastAPI** - Modern Python web framework with automatic API documentation
- **MongoDB** - Document database for user data and analytics storage
- **Spotipy** - Spotify Web API integration library
- **Docker** - Containerization with multi-stage builds
- **Nginx** - Reverse proxy and static file serving
- **Prometheus** - Application metrics and monitoring

### Infrastructure Layer  
- **AWS EKS** - Managed Kubernetes cluster with multi-AZ deployment
- **Terraform** - Infrastructure as Code with modular architecture
- **AWS ECR** - Private container registry
- **AWS Secrets Manager** - Secure credential management
- **VPC** - Custom networking with public/private subnets

### Deployment Layer
- **ArgoCD** - GitOps continuous deployment and sync
- **Helm** - Kubernetes package manager with dependency management  
- **Kubernetes** - Container orchestration with auto-scaling
- **Kind** - Local Kubernetes development environment

### Monitoring & Observability
- **Prometheus & Grafana** - Metrics collection and visualization
- **Elasticsearch & Kibana** - Centralized logging and analysis
- **Fluent Bit** - Log forwarding and processing
- **Cert-Manager** - Automated TLS certificate management

### CI/CD Pipeline
- **Jenkins** - Automated build, test, and deployment pipeline
- **GitHub Actions** - Self-hosted runner with automated testing and deployment
- **GitHub Webhooks** - Trigger builds on code changes
- **Slack Integration** - Build notifications and status updates
- **Multi-stage Testing** - Unit, integration, and end-to-end tests

### Jenkins Pipeline
![Architecture Overview](Jenkins_Pipeline.png)

## API Endpoints

| Endpoint | Method | Description |
|----------|---------|-------------|
| `/login` | GET | Initiate Spotify OAuth authentication |
| `/callback` | GET | Handle OAuth callback and create user session |
| `/dashboard` | GET | Main dashboard with user statistics |
| `/user/top_tracks` | GET | User's most played tracks |
| `/user/top_artists` | GET | User's favorite artists |
| `/user/top_genres` | GET | Music genre preferences and distribution |
| `/user/avg_popularity` | GET | Average popularity score of user's music |
| `/metrics` | GET | Prometheus metrics for monitoring |
| `/health` | GET | Application health check endpoint |
| `/logout` | GET | Clear user session and logout |


## Key Features

### **Secure Authentication**
- Spotify OAuth2 integration with secure token management
- Session-based user authentication
- Automatic token refresh handling

### **Real-time Analytics** 
- Live data fetching from Spotify Web API
- Historical data tracking and comparison
- Interactive dashboard with dynamic visualizations

### **Production-Ready Infrastructure**
- Multi-AZ EKS cluster deployment
- Auto-scaling based on demand
- HTTPS with automatic certificate management
- Health checks and graceful degradation

### **Comprehensive Monitoring**
- Application performance metrics
- Infrastructure health monitoring  
- Centralized logging with search capabilities
- Custom Grafana dashboards

### **GitOps Workflow**
- Automated deployment pipeline
- Infrastructure as Code
- Configuration drift detection
- Self-healing deployments

### **GitHub Actions CI/CD**
- **Self-hosted Runner** - Runs on cloud instance with container registry access
- **Automated Testing** - Unit and integration tests with MongoDB
- **Semantic Versioning** - Automatic version tagging (semver) on successful builds
- **Multi-branch Support** - Tests on feature branches, deploys only on main
- **GitOps Integration** - Updates Helm charts and triggers ArgoCD sync

## Quick Start

### Local Development
```bash
# Clone and start the application
docker-compose up

# Access the application
open http://localhost:8000
```

### Production Deployment
The application automatically deploys to AWS EKS through the GitOps pipeline when changes are pushed to the main branch.

## Architecture Highlights

- **Three-Repository Architecture**: Separate repositories for application code, infrastructure, and GitOps configurations
- **App-of-Apps Pattern**: ArgoCD manages multiple applications as a single unit
- **Security Best Practices**: Secrets management, network policies, and RBAC
- **Observability**: Complete monitoring stack with metrics, logs, and traces

## GitHub Actions Workflow

The project uses a comprehensive GitHub Actions workflow (`.github/workflows/build-and-push.yml`) that implements:

### **Workflow Triggers**
- `feature/*` branches - Run tests only
- `main` branch - Run tests + build + deploy  
- Pull requests to `main` - Run tests only

### **Pipeline Stages**

#### 1. **Test Job** (All Branches)
```yaml
- Checkout code
- Build test Docker image  
- Start MongoDB with docker-compose
- Run unit tests
- Run integration tests
- Cleanup containers
```

#### 2. **Build and Push Job** (Main Branch Only)
```yaml
- Checkout code with full history
- Generate semantic version (auto-increment patch)
- Create and push git tag
- Login to ECR using EC2 IAM role
- Build and push Docker images (latest + version tag)
- Update GitOps repository Helm charts
- Commit and push GitOps changes
```

### **Key Features**
- **Zero-downtime deployments** - ArgoCD detects GitOps changes and syncs automatically
- **Semantic versioning** - Automatic patch increment (1.0.0 → 1.0.1)
- **Multi-repository updates** - Updates both application and GitOps repositories
- **Comprehensive testing** - Both unit and integration tests with real MongoDB
- **Security** - Uses cloud IAM roles instead of storing credentials

### **Required Setup**
- Self-hosted GitHub runner on cloud instance with Docker and docker-compose
- Cloud IAM role with container registry push/pull permissions
- Personal Access Token (PAT) for GitOps repository access
- ArgoCD monitoring the GitOps repository for automatic deployments

## Repository Structure

This is part of a larger project with three interconnected components:
- **main/** - FastAPI application source code
- **infra/** - Terraform infrastructure modules for cloud deployment
- **gitops/** - Kubernetes manifests and Helm charts for container orchestration

For detailed setup instructions and development guidelines, see [CLAUDE.md](CLAUDE.md).

---

*This project demonstrates production-grade software engineering practices including cloud-native architecture, DevOps automation, and modern development workflows.*
