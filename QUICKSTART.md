# Quick Start Guide

## Prerequisites Check

```bash
# Check kubectl
kubectl version --client

# Check cluster access
kubectl cluster-info

# Check ingress controller
kubectl get pods -n traefik
```

## Deployment Steps

### Step 1: Configure Settings

1. Edit `k8s/base/ingress.yaml` and replace `excalidraw.example.com` with your actual domain
2. Edit `k8s/base/configmap.yaml` and update URLs with your domain
3. (Optional) Edit `k8s/base/pvc.yaml` and uncomment/set the `storageClassName`

### Step 2: Build Docker Images

```bash
./build.sh
```

**Note**: If you're using a container registry, tag and push images:

```bash
docker tag excalidraw-client:latest your-registry/excalidraw-client:latest
docker tag excalidraw-server:latest your-registry/excalidraw-server:latest
docker tag excalidraw-socket:latest your-registry/excalidraw-socket:latest

docker push your-registry/excalidraw-client:latest
docker push your-registry/excalidraw-server:latest
docker push your-registry/excalidraw-socket:latest
```

Then update the image references in deployment files.

### Step 3: Deploy to Kubernetes

```bash
./deploy.sh
```

Or manually:

```bash
# Deploy client first
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/client/deployment.yaml
kubectl apply -f k8s/client/service.yaml

# Deploy server second
kubectl apply -f k8s/base/pvc.yaml
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/server/deployment.yaml
kubectl apply -f k8s/server/service.yaml

# Deploy ingress
kubectl apply -f k8s/base/ingress.yaml

# (Optional) Deploy socket server last
kubectl apply -f k8s/socket/deployment.yaml
kubectl apply -f k8s/socket/service.yaml
```

### Step 4: Verify Deployment

```bash
# Check all resources
kubectl get all -n excalidraw

# Check ingress
kubectl get ingress -n excalidraw

# Check logs
kubectl logs -f deployment/excalidraw-client -n excalidraw
kubectl logs -f deployment/excalidraw-server -n excalidraw
```

### Step 5: Configure DNS

1. Get the ingress external IP:
```bash
kubectl get ingress -n excalidraw
```

2. Add DNS A record pointing your domain to the ingress IP

### Step 6: Access the Application

- Web UI: `https://your-domain.com/`
- Files: `https://your-domain.com/files/`

## Adding .excalidraw Files

### Method 1: Copy files directly to pod

```bash
kubectl cp your-file.excalidraw \
  $(kubectl get pod -n excalidraw -l component=server -o jsonpath='{.items[0].metadata.name}'):/data/excalidraw/ \
  -n excalidraw
```

### Method 2: Use kubectl exec

```bash
kubectl exec -n excalidraw deployment/excalidraw-server -- \
  sh -c "cat > /data/excalidraw/your-file.excalidraw" < your-file.excalidraw
```

### Method 3: Access PersistentVolume directly

If you have access to the cluster nodes:

```bash
# Find the PV
kubectl get pv

# Access the node and volume location
# Copy files to the volume path
```

## Enabling Socket Server (Optional)

1. Edit `k8s/base/kustomization.yaml` and uncomment:
```yaml
  - ../socket/deployment.yaml
  - ../socket/service.yaml
```

2. Apply changes:
```bash
kubectl apply -k k8s/base/
```

## ArgoCD Integration

In your `manamana32321/homelab` repository, create:

**apps/excalidraw/application.yaml**:
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

Apply:
```bash
kubectl apply -f apps/excalidraw/application.yaml
```

## Troubleshooting

### Images not pulling
- Make sure images are built: `docker images | grep excalidraw`
- For remote clusters, push to a registry and update image references

### PVC pending
- Check storage class: `kubectl get storageclass`
- Update `k8s/base/pvc.yaml` with available storage class

### Ingress not working
- Verify ingress controller is running
- Check ingress events: `kubectl describe ingress excalidraw-ingress -n excalidraw`
- Verify DNS is configured correctly

### Can't access files
- Check server logs: `kubectl logs deployment/excalidraw-server -n excalidraw`
- Verify PVC is mounted: `kubectl describe pod -n excalidraw -l component=server`
