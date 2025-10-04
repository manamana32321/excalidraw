# Changes Summary

This document describes the changes made to simplify the Excalidraw Kubernetes deployment by using official Docker images.

## What Changed

### Removed Files
- `build.sh` - No longer needed as we use official images
- `k8s/client/Dockerfile` - Replaced with official `excalidraw/excalidraw:latest`
- `k8s/client/nginx.conf` - No longer needed
- `k8s/server/Dockerfile` - Replaced with standard `nginx:alpine`
- `k8s/server/server-nginx.conf` - No longer needed
- `k8s/server/start.sh` - No longer needed
- `k8s/socket/Dockerfile` - Replaced with official `excalidraw/excalidraw-room:latest`

### Modified Files

#### Deployments
- **k8s/client/deployment.yaml**: Now uses `excalidraw/excalidraw:latest` (official image)
- **k8s/server/deployment.yaml**: Now uses `nginx:alpine` for file serving
- **k8s/socket/deployment.yaml**: Now uses `excalidraw/excalidraw-room:latest` (official collaboration image)

#### Services
- **k8s/server/service.yaml**: Updated port from 8080 to 80 (standard nginx port)

#### Ingress
- **k8s/base/ingress.yaml**: Updated server port from 8080 to 80

#### Scripts
- **Makefile**: Removed all build-related targets (build, build-client, build-server, build-socket)
- **deploy.sh**: Updated to reflect that no building is required

#### Documentation
- **README.md**: Removed build instructions section
- **QUICKSTART.md**: Removed build step from deployment guide
- **한국어_가이드.md**: Removed build instructions and updated to reflect official image usage

## Benefits

1. **Simpler Deployment**: No need to build Docker images locally
2. **Faster Setup**: Can deploy immediately without waiting for builds
3. **Official Images**: Uses maintained, tested images from Excalidraw team
4. **Smaller Repository**: Removed custom Dockerfiles and build scripts
5. **Easier Updates**: Just restart deployments to pull latest official images

## How to Deploy

### Quick Start
```bash
./deploy.sh
```

### Manual Deployment
```bash
# Deploy everything at once using Kustomize
kubectl apply -k k8s/base/

# Or deploy components individually
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/client/deployment.yaml
kubectl apply -f k8s/client/service.yaml
kubectl apply -f k8s/server/deployment.yaml
kubectl apply -f k8s/server/service.yaml
kubectl apply -f k8s/base/ingress.yaml
```

### Using Makefile
```bash
# Deploy everything
make deploy

# Or deploy with Kustomize
make deploy-kustomize

# Check status
make status

# View logs
make logs
```

## Images Used

| Component | Image | Purpose |
|-----------|-------|---------|
| Client | `excalidraw/excalidraw:latest` | Official Excalidraw web application |
| Server | `nginx:alpine` | Simple file server for .excalidraw files |
| Socket | `excalidraw/excalidraw-room:latest` | Official collaboration server (optional) |

## Upgrading

To upgrade to the latest version:
```bash
kubectl rollout restart deployment -n excalidraw
```

The deployments will automatically pull the latest images from Docker Hub.

## Configuration Required

Before deploying, update these files:
1. `k8s/base/ingress.yaml` - Set your domain name
2. `k8s/base/configmap.yaml` - Update URLs with your domain
3. `k8s/base/pvc.yaml` - (Optional) Set storage class if needed
