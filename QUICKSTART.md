# Quick Start Guide

Get Excalidraw up and running in your Kubernetes cluster using official Docker images.

## Prerequisites Check

```bash
# Check kubectl
kubectl version --client

# Check cluster access
kubectl cluster-info

# Check ingress controller
kubectl get pods -n ingress-nginx
```

## Deployment Steps

### Step 1: Configure Settings

1. Edit `k8s/base/ingress.yaml` and replace `excalidraw.json-server.win` with your actual domain
1. Edit `k8s/base/ingress.yaml` and replace `excalidraw.json-server.win` with your actual domain
2. Edit `k8s/base/configmap.yaml` and update URLs with your domain
3. (Optional) Edit `k8s/base/pvc.yaml` and uncomment/set the `storageClassName`

### Step 2: Deploy to Kubernetes

```bash
./deploy.sh
```

Or manually:

```bash
# Deploy using Kustomize (recommended)
kubectl apply -k k8s/base/

# Or deploy components individually
kubectl apply -f k8s/base/namespace.yaml
kubectl apply -f k8s/client/deployment.yaml
kubectl apply -f k8s/client/service.yaml
kubectl apply -f k8s/base/pvc.yaml
kubectl apply -f k8s/base/configmap.yaml
kubectl apply -f k8s/server/deployment.yaml
kubectl apply -f k8s/server/service.yaml
kubectl apply -f k8s/base/ingress.yaml

# (Optional) Deploy socket server for collaboration
kubectl apply -f k8s/socket/deployment.yaml
kubectl apply -f k8s/socket/service.yaml
```

### Step 3: Verify Deployment

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

- Check if pods are pulling the official images correctly
- For private registries, create imagePullSecrets and reference them in deployments

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
