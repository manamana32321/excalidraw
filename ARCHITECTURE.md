# Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet / Users                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS
                             │
┌────────────────────────────▼────────────────────────────────────┐
│                    Kubernetes Cluster                            │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Ingress Controller                      │  │
│  │                 (excalidraw.json-server.win)                   │  │
│  └───────┬─────────────────┬──────────────────┬───────────────┘  │
│          │                 │                  │                  │
│    / (root)         /files (files)      /socket (optional)      │
│          │                 │                  │                  │
│  ┌───────▼────────┐ ┌──────▼─────────┐ ┌─────▼──────────┐      │
│  │ excalidraw-    │ │ excalidraw-    │ │ excalidraw-    │      │
│  │ client         │ │ server         │ │ socket         │      │
│  │ Service        │ │ Service        │ │ Service        │      │
│  │ ClusterIP:80   │ │ ClusterIP:8080 │ │ ClusterIP:3002 │      │
│  └───────┬────────┘ └──────┬─────────┘ └─────┬──────────┘      │
│          │                 │                  │                  │
│  ┌───────▼────────┐ ┌──────▼─────────┐ ┌─────▼──────────┐      │
│  │ Client         │ │ Server         │ │ Socket         │      │
│  │ Deployment     │ │ Deployment     │ │ Deployment     │      │
│  │ (2 replicas)   │ │ (1 replica)    │ │ (1 replica)    │      │
│  └────────────────┘ └──────┬─────────┘ └────────────────┘      │
│                             │                                    │
│                     ┌───────▼────────┐                          │
│                     │ PersistentVol  │                          │
│                     │ /data/excalidraw│                         │
│                     │ (10Gi storage) │                          │
│                     └────────────────┘                          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Client (First to Deploy)

- **Image**: Built from official Excalidraw repo
- **Technology**: React app served by Nginx
- **Port**: 80
- **Replicas**: 2 (for HA)
- **Path**: `/` (root)
- **Purpose**: Web UI for drawing

### 2. Server (Second to Deploy)

- **Image**: Excalidraw storage backend
- **Port**: 8080
- **Replicas**: 1
- **Path**: `/files`
- **Storage**: PersistentVolumeClaim (10Gi)
- **Purpose**: Store and serve .excalidraw files
- **Features**:
  - RESTful API for file operations
  - CORS enabled
  - Purpose-built for Excalidraw files

### 3. Socket Server (Optional, Last to Deploy)

- **Image**: Built from Excalidraw collaboration server
- **Technology**: Node.js WebSocket server
- **Port**: 3002
- **Replicas**: 1
- **Path**: `/socket`
- **Purpose**: Real-time collaboration

## Data Flow

### Drawing Creation/Editing

```
User Browser
    ↓ (HTTPS)
Ingress (/)
    ↓
Client Service
    ↓
Client Pod (Nginx)
    ↓ (serves React app)
User Browser
```

### File Access

```
User Browser
    ↓ (HTTPS GET)
Ingress (/files/*)
    ↓
Server Service
    ↓
Server Pod (Nginx)
    ↓
PersistentVolume (/data/excalidraw)
    ↓
File returned to browser
```

### File Upload

```
User/Script
    ↓ (kubectl cp or WebDAV PUT)
Server Pod
    ↓
PersistentVolume
    ↓
Files stored permanently
```

### Real-time Collaboration (Optional)

```
User Browser A           User Browser B
    ↓                        ↓
    └─── WebSocket ─────────┘
            ↓
        Ingress (/socket)
            ↓
        Socket Service
            ↓
        Socket Pod
            ↓
    Collaboration room
```

## Deployment Order

```
Step 1: Namespace + PVC
    ↓
Step 2: Client (must be first)
    ↓
Step 3: Server (must be second)
    ↓
Step 4: Ingress
    ↓
Step 5: Socket Server (optional, last)
```

## External Access

### URLs

- **Web UI**: `https://excalidraw.json-server.win/`
- **Files**: `https://excalidraw.json-server.win/files/`
- **File Access**: `https://excalidraw.json-server.win/files/myfile.excalidraw`
- **Socket**: `wss://excalidraw.json-server.win/socket` (if enabled)

### DNS Configuration

```
excalidraw.json-server.win  →  A Record  →  <Ingress IP>
```

## Storage

### PersistentVolumeClaim

- **Name**: excalidraw-storage-pvc
- **Size**: 10Gi
- **Access**: ReadWriteOnce
- **Mount**: /data/excalidraw in server pod

### File Organization

```
/data/excalidraw/
├── drawing1.excalidraw
├── drawing2.excalidraw
├── project/
│   ├── diagram1.excalidraw
│   └── diagram2.excalidraw
└── archive/
    └── old-drawing.excalidraw
```

## Resource Requirements

### Client

- **CPU**: 100m request, 200m limit
- **Memory**: 128Mi request, 256Mi limit
- **Replicas**: 2

### Server

- **CPU**: 100m request, 200m limit
- **Memory**: 128Mi request, 256Mi limit
- **Replicas**: 1
- **Storage**: 10Gi

### Socket (Optional)

- **CPU**: 200m request, 500m limit
- **Memory**: 256Mi request, 512Mi limit
- **Replicas**: 1

## High Availability

- **Client**: 2 replicas with anti-affinity (recommended)
- **Server**: 1 replica (RWO storage limitation)
- **Socket**: 1 replica (stateless, can scale if needed)
- **Ingress**: Depends on ingress controller HA setup

## Security

### Network Policies (Not yet implemented, can be added)

```
- Client can access: Internet, Server, Socket
- Server can access: PersistentVolume
- Socket can access: None (accepts connections)
```

### RBAC (Default)

- Uses default service account
- Can be customized for stricter access

### TLS/SSL

- Configured in ingress (commented, ready to enable)
- Supports cert-manager for automatic certificates

## Monitoring & Observability

### Health Checks

- **Liveness probes**: Ensure pods are running
- **Readiness probes**: Ensure pods are ready for traffic

### Logs

- Client logs: `kubectl logs deployment/excalidraw-client -n excalidraw`
- Server logs: `kubectl logs deployment/excalidraw-server -n excalidraw`
- Socket logs: `kubectl logs deployment/excalidraw-socket -n excalidraw`

### Metrics (Can be added)

- Prometheus monitoring
- Grafana dashboards
- Request/response metrics

## Backup & Recovery

### Backup Strategy

```bash
# Backup PersistentVolume data
kubectl exec -n excalidraw deployment/excalidraw-server -- \
  tar -czf - /data/excalidraw > backup-$(date +%Y%m%d).tar.gz
```

### Recovery

```bash
# Restore from backup
kubectl exec -n excalidraw deployment/excalidraw-server -- \
  tar -xzf - -C / < backup-YYYYMMDD.tar.gz
```

## Scaling

### Horizontal Scaling

- **Client**: Can scale to N replicas (increase in deployment.yaml)
- **Server**: Limited to 1 replica (RWO storage)
- **Socket**: Can scale if using Redis for state sharing

### Vertical Scaling

- Adjust resource limits in deployment manifests
- Increase PVC size if storage fills up

## Integration Points

### With HomeOps/ArgoCD

```
GitHub: manamana32321/excalidraw (this repo)
    ↓ (GitOps)
ArgoCD Application (in homelab repo)
    ↓ (syncs)
Kubernetes Cluster
```

### With External Systems

- **Authentication**: Can add OAuth proxy
- **Storage**: Can use NFS, Ceph, or cloud storage
- **CDN**: Can add CloudFlare in front of ingress
- **Monitoring**: Can integrate with existing Prometheus/Grafana
