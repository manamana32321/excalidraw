# Excalidraw Kubernetes Deployment

Personal Excalidraw deployment for on-premise Kubernetes cluster.

## Overview

This repository contains Kubernetes manifests and Docker configurations for deploying Excalidraw to an on-premise Kubernetes cluster. The deployment includes:

- **Client**: Excalidraw web application
- **Server**: Storage backend for .excalidraw files
- **Socket Server**: Optional WebSocket server for real-time collaboration

## Architecture

- **Client**: Nginx-based static file server serving the Excalidraw web application
- **Server**: Nginx-based file server with persistent storage for .excalidraw files
- **Socket Server** (Optional): Node.js WebSocket server for real-time collaboration
- **Ingress**: Routes external traffic to client and exposes .excalidraw files

## Prerequisites

- Kubernetes cluster (v1.19+)
- kubectl configured to access your cluster
- Docker (for building images)
- Ingress controller installed in your cluster (e.g., nginx-ingress)
- Storage class configured for PersistentVolumeClaims

## Directory Structure

```
k8s/
├── base/
│   ├── namespace.yaml        # Namespace definition
│   ├── configmap.yaml        # Configuration settings
│   ├── pvc.yaml              # Persistent Volume Claim for storage
│   ├── ingress.yaml          # Ingress configuration
│   └── kustomization.yaml    # Kustomize configuration
├── client/
│   ├── Dockerfile            # Client Docker image
│   ├── nginx.conf            # Client nginx configuration
│   ├── deployment.yaml       # Client deployment
│   └── service.yaml          # Client service
├── server/
│   ├── Dockerfile            # Server Docker image
│   ├── server-nginx.conf     # Server nginx configuration
│   ├── start.sh              # Server startup script
│   ├── deployment.yaml       # Server deployment
│   └── service.yaml          # Server service
└── socket/
    ├── Dockerfile            # Socket server Docker image
    ├── deployment.yaml       # Socket deployment (optional)
    └── service.yaml          # Socket service (optional)
```

## Configuration

Before deploying, update the following files with your environment-specific settings:

1. **k8s/base/ingress.yaml**: Update `host` with your domain name
2. **k8s/base/configmap.yaml**: Update URLs with your domain
3. **k8s/base/pvc.yaml**: Uncomment and set `storageClassName` if needed

## Building Images

Build all Docker images:

```bash
./build.sh
```

Or build individually:

```bash
# Build client
cd k8s/client && docker build -t excalidraw-client:latest .

# Build server
cd k8s/server && docker build -t excalidraw-server:latest .

# Build socket server (optional)
cd k8s/socket && docker build -t excalidraw-socket:latest .
```

## Deployment

### Quick Deploy

Deploy everything with the provided script:

```bash
./deploy.sh
```

### Manual Deployment

1. **Deploy Client** (first):
```bash
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/client/deployment.yaml
kubectl apply -f k8s/client/service.yaml
```

2. **Deploy Server** (second):
```bash
kubectl apply -f k8s/base/pvc.yaml
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/server/deployment.yaml
kubectl apply -f k8s/server/service.yaml
```

3. **Deploy Ingress**:
```bash
kubectl apply -f k8s/base/ingress.yaml
```

4. **Deploy Socket Server** (optional, last):
```bash
# Uncomment socket resources in k8s/base/kustomization.yaml
kubectl apply -f k8s/socket/deployment.yaml
kubectl apply -f k8s/socket/service.yaml
```

### Using Kustomize

Deploy everything using Kustomize:

```bash
kubectl apply -k k8s/base/
```

## Accessing the Application

1. Get the ingress IP:
```bash
kubectl get ingress -n excalidraw
```

2. Configure your DNS to point your domain to the ingress IP

3. Access the application:
   - Client: `https://excalidraw.example.com/`
   - Files: `https://excalidraw.example.com/files/`

## File Storage

- All .excalidraw files are stored in the persistent volume at `/data/excalidraw`
- Files are accessible via the `/files` path through the ingress
- The server provides a directory listing at `/files` for browsing

## Uploading Files

To upload .excalidraw files to the server:

```bash
# Copy file to the server pod
kubectl cp your-file.excalidraw excalidraw-server-<pod-id>:/data/excalidraw/ -n excalidraw

# Or use kubectl exec to upload
kubectl exec -n excalidraw deployment/excalidraw-server -- sh -c "cat > /data/excalidraw/your-file.excalidraw" < your-file.excalidraw
```

## Monitoring

Check deployment status:

```bash
# All resources
kubectl get all -n excalidraw

# Pods
kubectl get pods -n excalidraw

# Logs
kubectl logs -f deployment/excalidraw-client -n excalidraw
kubectl logs -f deployment/excalidraw-server -n excalidraw
```

## Troubleshooting

### Pod not starting
```bash
kubectl describe pod <pod-name> -n excalidraw
kubectl logs <pod-name> -n excalidraw
```

### Storage issues
```bash
kubectl get pvc -n excalidraw
kubectl describe pvc excalidraw-storage-pvc -n excalidraw
```

### Ingress not working
```bash
kubectl describe ingress excalidraw-ingress -n excalidraw
```

## Integration with ArgoCD

For ArgoCD deployment, create an Application manifest in your `manamana32321/homelab` repository pointing to this repository:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: excalidraw
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/manamana32321/excalidraw
    targetRevision: main
    path: k8s/base
  destination:
    server: https://kubernetes.default.svc
    namespace: excalidraw
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## Upgrading

To upgrade to a newer version of Excalidraw:

1. Rebuild the Docker images: `./build.sh`
2. Update the deployment: `kubectl rollout restart deployment -n excalidraw`

## Cleanup

Remove all resources:

```bash
kubectl delete namespace excalidraw
```

## License

This deployment configuration is for personal use. Excalidraw itself is licensed under MIT License.
