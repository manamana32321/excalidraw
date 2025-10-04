# Traefik Ingress Controller Setup Guide

This guide helps you set up Traefik as the ingress controller for your Kubernetes cluster to work with this Excalidraw deployment.

## Why Traefik?

Traefik is a modern, cloud-native ingress controller that provides:
- Automatic service discovery
- Built-in Let's Encrypt support
- WebSocket and gRPC support
- Rich middleware options
- Dynamic configuration

## Prerequisites

- Kubernetes cluster (v1.19+)
- kubectl configured to access your cluster
- Helm (recommended for installation)

## Installation Methods

### Method 1: Using Helm (Recommended)

1. **Add the Traefik Helm repository**:
```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
```

2. **Install Traefik**:
```bash
# Create traefik namespace
kubectl create namespace traefik

# Install Traefik with default configuration
helm install traefik traefik/traefik -n traefik
```

3. **Verify installation**:
```bash
kubectl get pods -n traefik
kubectl get svc -n traefik
```

### Method 2: Using kubectl with manifests

1. **Download Traefik CRDs**:
```bash
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml
```

2. **Download and apply Traefik RBAC and deployment**:
```bash
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml
```

3. **Create Traefik service**:
```bash
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v2.10/examples/k8s/traefik-service.yml
```

## Configuration for Excalidraw

### Basic Configuration

The default Traefik installation should work with this Excalidraw deployment. The ingress configuration in `k8s/base/ingress.yaml` is already configured with Traefik annotations.

### Custom Configuration (Optional)

If you want to customize Traefik, create a `values.yaml` file:

```yaml
# values.yaml
service:
  type: LoadBalancer
  
ingressRoute:
  dashboard:
    enabled: true

ports:
  web:
    port: 80
    exposedPort: 80
  websecure:
    port: 443
    exposedPort: 443

logs:
  general:
    level: INFO
  access:
    enabled: true
```

Install with custom values:
```bash
helm install traefik traefik/traefik -n traefik -f values.yaml
```

## Enabling HTTPS/TLS

### Using Let's Encrypt with Traefik

1. **Update Traefik configuration to enable Let's Encrypt**:
```yaml
# values.yaml
additionalArguments:
  - "--certificatesresolvers.letsencrypt.acme.email=your-email@example.com"
  - "--certificatesresolvers.letsencrypt.acme.storage=/data/acme.json"
  - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"

persistence:
  enabled: true
  path: /data
```

2. **Update the Excalidraw ingress** (`k8s/base/ingress.yaml`):
```yaml
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt
spec:
  tls:
  - hosts:
    - excalidraw.example.com
    secretName: excalidraw-tls
```

### Using Cert-Manager (Alternative)

If you prefer cert-manager for certificate management:

1. **Install cert-manager**:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

2. **Create ClusterIssuer**:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
```

3. **Update ingress with cert-manager annotation**:
```yaml
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    traefik.ingress.kubernetes.io/router.entrypoints: websecure
    traefik.ingress.kubernetes.io/router.tls: "true"
```

## Getting the Ingress IP

After Traefik is installed, get the external IP:

```bash
# For LoadBalancer service
kubectl get svc traefik -n traefik

# For NodePort service
kubectl get nodes -o wide
kubectl get svc traefik -n traefik -o jsonpath='{.spec.ports[?(@.name=="web")].nodePort}'
```

Configure your DNS to point your domain (e.g., `excalidraw.example.com`) to this IP address.

## Troubleshooting

### Check Traefik Status
```bash
kubectl get pods -n traefik
kubectl logs -n traefik deployment/traefik
```

### Check Ingress Status
```bash
kubectl get ingress -n excalidraw
kubectl describe ingress excalidraw-ingress -n excalidraw
```

### Common Issues

1. **Ingress not accessible**:
   - Verify Traefik is running: `kubectl get pods -n traefik`
   - Check service type: `kubectl get svc -n traefik`
   - Verify DNS is pointing to the correct IP

2. **Certificate issues**:
   - Check Let's Encrypt rate limits
   - Verify email is configured correctly
   - Check cert-manager logs if using cert-manager

3. **404 errors**:
   - Verify ingress rules are correct
   - Check that services exist: `kubectl get svc -n excalidraw`
   - Verify pod selectors match

## Migrating from nginx-ingress

If you're migrating from nginx-ingress:

1. **Scale down nginx-ingress**:
```bash
kubectl scale deployment nginx-ingress-controller -n ingress-nginx --replicas=0
```

2. **Install Traefik** (using methods above)

3. **Update ingress annotations** (already done in this repository)

4. **Test the deployment**

5. **Remove nginx-ingress** (optional):
```bash
helm uninstall nginx-ingress -n ingress-nginx
```

## Resources

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Traefik Kubernetes Ingress](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Traefik Let's Encrypt](https://doc.traefik.io/traefik/https/acme/)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)

## Quick Start

For a quick start with default settings:

```bash
# Install Traefik
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik -n traefik --create-namespace

# Wait for Traefik to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n traefik --timeout=300s

# Get Traefik service IP
kubectl get svc traefik -n traefik

# Deploy Excalidraw
cd excalidraw
./build.sh
./deploy.sh

# Configure DNS to point to Traefik IP
# Then access your application at https://your-domain.com
```

That's it! Your Excalidraw deployment should now be accessible through Traefik.
