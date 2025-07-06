# **homelab-docs**

A containerized documentation server that automatically builds and serves MkDocs documentation from any Git repository. Originally designed for [llajas/homelab](https://github.com/llajas/homelab), but configurable for any repository.

## **Why?**

The [llajas/homelab](https://github.com/llajas/homelab) repository includes documentation that requires:
1. Cloning the repository locally
2. Installing Python dependencies (`mkdocs-material`)
3. Running `make docs` to serve on port `8000`

This container **simplifies and automates** that entire process:
- ✅ **Zero Setup**: No local dependencies required
- ✅ **Auto-Updates**: Watches for repository changes every 2 minutes
- ✅ **Production Ready**: Includes health checks, logging, and security hardening
- ✅ **Flexible Deployment**: Docker Compose, Kubernetes, or standalone Docker

## **How It Works**

This is a **single-container solution** based on `nginx:alpine` that:

### **Build Process**
1. **Clones** the specified Git repository  
2. **Builds** documentation using `mkdocs-material`
3. **Serves** via nginx on port 80
4. **Monitors** for updates every 2 minutes (configurable)
5. **Rebuilds** automatically when changes are detected

### **Key Features**
- 🔄 **Continuous Updates**: Automatically pulls and rebuilds on repository changes
- 🔒 **Security Hardened**: Runs as non-root user (UID 1001) with minimal privileges
- 📊 **Health Monitoring**: Built-in health checks and structured logging
- 🎛️ **Highly Configurable**: Repository URL and update interval via environment variables
- 📝 **Complete Logging**: Application logs + nginx access logs with visitor IPs
- 🚀 **Multiple Deployment Options**: Docker Compose, Kubernetes Helm chart, or standalone
- ⚡ **Production Ready**: Resource limits, anti-affinity, and autoscaling support
- 🌐 **Cloudflare Integration**: Helm chart optimized for Cloudflared tunnels

## **Quick Start**

### **Option 1: Docker Compose (Recommended for local development)**
```bash
# Clone this repository
git clone <this-repo-url>
cd homelab-docs

# Run with default settings (llajas/homelab repo)
make run

# Or run in development mode (with logs)
make dev

# Stop when done
make stop
```

### **Option 2: Custom Repository**
```bash
# Copy environment template
cp .env.example .env

# Edit .env to set your repository
vim .env  # Set REPO_URL=https://github.com/yourusername/your-docs-repo

# Run with your custom repository
docker-compose up -d
```

### **Option 3: Kubernetes with Helm**
```bash
# Install to Kubernetes cluster
make helm-install

# Upgrade existing deployment
make helm-upgrade

# Uninstall
make helm-uninstall
```

### **Option 4: Standalone Docker**
```bash
# Build and run directly
docker build -t homelab-docs --build-arg REPO_URL=https://github.com/yourusername/your-repo .
docker run -d -p 5000:80 homelab-docs
```

## **Configuration**

### **Environment Variables**
| Variable | Default | Description |
|----------|---------|-------------|
| `REPO_URL` | `https://github.com/llajas/homelab` | Git repository to build docs from |
| `UPDATE_INTERVAL` | `120` | How often to check for updates (seconds) |

### **Makefile Variables**
| Variable | Default | Description |
|----------|---------|-------------|
| `REGISTRY` | `registry.lajas.tech` | Docker registry for pushing images |
| `REPO` | `homelab-documenatation` | Repository name in registry |
| `REPO_URL` | `https://github.com/llajas/homelab` | Git repository URL |

### **Custom Repository Setup**
```bash
# Method 1: Environment variable
export REPO_URL=https://github.com/yourusername/your-docs-repo
make build

# Method 2: .env file
cp .env.example .env
# Edit .env with your settings
docker-compose up

# Method 3: Build argument
docker build --build-arg REPO_URL=https://github.com/yourusername/your-repo .
```

## **Available Commands**

### **Docker Compose**
```bash
make run      # Start in background
make dev      # Start with logs visible
make stop     # Stop and remove containers
```

### **Docker Build & Push**
```bash
make build    # Build container image
make push     # Push to registry
make all      # Build and push
```

### **Kubernetes Deployment**
```bash
make helm-install    # Install Helm chart
make helm-upgrade    # Upgrade existing deployment
make helm-uninstall  # Remove from cluster
make helm-template   # Preview generated YAML
```

## **Kubernetes Features**

The included Helm chart provides production-ready Kubernetes deployment with:

- 🔄 **Multiple Replicas**: Run 2+ instances for high availability (default: 2)
- 🌐 **Ingress Support**: Easy setup for external access (perfect for Cloudflared)
- 📈 **Horizontal Pod Autoscaling**: Automatically scale based on CPU usage (2-10 replicas)
- 🎯 **Pod Anti-Affinity**: Spread replicas across different nodes for resilience
- 🛡️ **Security Hardened**: Non-root execution (UID 1001) with dropped capabilities
- ❤️ **Health Checks**: Kubernetes-native liveness and readiness probes
- 📊 **Resource Management**: CPU/memory requests and limits configured
- 🚀 **Rolling Updates**: Zero-downtime deployments with configurable strategy

### **Helm Values Overview**
```yaml
# Key configuration options
replicaCount: 2
config:
  repoUrl: "https://github.com/llajas/homelab"
  updateInterval: 120

# Resource limits
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

# High availability
affinity:
  podAntiAffinity: enabled  # Spreads pods across nodes

# Autoscaling (disabled by default)
autoscaling:
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

### **Helm Configuration Examples**

```bash
# Deploy with custom repository
helm install homelab-docs ./helm/homelab-docs \
  --set config.repoUrl=https://github.com/yourusername/your-docs \
  --set replicaCount=3

# Enable ingress for external access via Cloudflared
helm upgrade homelab-docs ./helm/homelab-docs \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=docs.yourdomain.com \
  --set ingress.annotations."external-dns\.alpha\.kubernetes\.io/target"=your-tunnel.example.com

# Enable autoscaling for traffic spikes
helm upgrade homelab-docs ./helm/homelab-docs \
  --set autoscaling.enabled=true \
  --set autoscaling.maxReplicas=5

# Production deployment with custom settings
helm install homelab-docs ./helm/homelab-docs \
  --set config.repoUrl=https://github.com/company/docs \
  --set config.updateInterval=300 \
  --set replicaCount=3 \
  --set resources.requests.memory=256Mi \
  --set ingress.enabled=true
```

## **Monitoring & Logs**

### **Application Logs**
```bash
# Docker Compose
docker-compose logs -f

# Kubernetes
kubectl logs -f deployment/homelab-docs
```

### **Log Format**
The container produces two types of logs:

**Application Logs** (build/deployment activities):
```
[2025-07-06 10:30:15] Starting build process...
[2025-07-06 10:30:20] Build and deploy completed successfully
[2025-07-06 10:32:15] Updates detected, rebuilding...
```

**Nginx Access Logs** (visitor requests):
```
192.168.1.100 - - [06/Jul/2025:10:31:45 +0000] "GET / HTTP/1.1" 200 1234
192.168.1.101 - - [06/Jul/2025:10:32:12 +0000] "GET /docs/ HTTP/1.1" 200 5678
```

## **Troubleshooting**

### **Common Issues**

**Build Fails**: Check that your repository has a valid `mkdocs.yml` file
```bash
# Check container logs
docker-compose logs homelab-docs

# Test build manually
docker exec -it homelab-docs_homelab-docs_1 /bin/sh
cd /tmp/repo && mkdocs build
```

**Updates Not Detected**: Verify the repository branch
```bash
# The container checks the 'master' branch by default
# If your repo uses 'main', you'll need to modify the entrypoint script
# Future versions will auto-detect the default branch
```

**Permission Issues**: The container runs as user 1001
```bash
# Ensure your repository is publicly accessible
# For private repos, you'll need to add SSH keys or tokens
```

**Helm Template Errors**: Validate your chart
```bash
# Test template rendering
make helm-template

# Debug with verbose output
helm template homelab-docs ./helm/homelab-docs --debug
```

**Resource Limits**: Adjust if builds fail due to memory/CPU constraints
```bash
# Increase resources in values.yaml or via --set
helm upgrade homelab-docs ./helm/homelab-docs \
  --set resources.limits.memory=1Gi \
  --set resources.limits.cpu=1000m
```

## **Why Not GitHub Pages?**

While GitHub Pages is excellent, this self-hosted approach provides:
- 🏠 **Full Control**: Host anywhere (homelab, VPS, cloud)
- 🔄 **Real-time Updates**: No GitHub Actions delay
- 🎛️ **Customization**: Modify the build process as needed
- 📚 **Learning**: Hands-on experience with containerization and Kubernetes
- 🌐 **Independence**: Not tied to GitHub's infrastructure

## **Contributing**

1. Fork this repository
2. Make your changes
3. Test with your own documentation repository
4. Submit a pull request

## **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
