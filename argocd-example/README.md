# ArgoCD Application Examples

This directory contains example ArgoCD Application manifests for deploying Excalidraw to your Kubernetes cluster.

## Files

- **application.yaml**: Basic Excalidraw deployment (client + server)
- **application-with-socket.yaml**: Full deployment including socket server

## Usage

These files should be placed in your `manamana32321/homelab` repository, typically in an `apps/` or `argocd/` directory.

### Basic Deployment

```bash
kubectl apply -f application.yaml
```

### With Socket Server

```bash
kubectl apply -f application-with-socket.yaml
```

## Configuration

Before applying, make sure to:

1. Update domain names in the source repository:
   - `k8s/base/ingress.yaml`
   - `k8s/base/configmap.yaml`

2. (Optional) Commit configuration overlays in your homelab repo for environment-specific settings

## Monitoring

Check the application status:

```bash
# Using ArgoCD CLI
argocd app get excalidraw

# Using kubectl
kubectl get application excalidraw -n argocd
```

View sync status:

```bash
argocd app sync excalidraw
```

## Sync Policy

Both examples use:
- **Automated sync**: Changes in the Git repo are automatically applied
- **Self-heal**: Cluster state is restored if manually modified
- **Prune**: Removed resources in Git are deleted from cluster
- **CreateNamespace**: Namespace is created automatically

## Customization

To customize for your environment, consider:

1. Creating a kustomize overlay in your homelab repo
2. Referencing the overlay in the Application spec
3. Keeping environment-specific configs (domain, storage class, etc.) in homelab

Example structure in homelab repo:
```
apps/
├── excalidraw/
│   ├── application.yaml
│   ├── overlays/
│   │   └── production/
│   │       ├── kustomization.yaml
│   │       ├── ingress-patch.yaml
│   │       └── configmap-patch.yaml
```
