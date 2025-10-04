# Migration from Nginx to Traefik/Caddy

## Summary of Changes

This migration replaces the nginx-based architecture with a Traefik/Caddy architecture as requested in the issue "nginx 대신 traefik 사용" (Use Traefik instead of nginx).

## Key Changes

### 1. Web Server Migration (nginx → Caddy)

Since Traefik is primarily an ingress controller/reverse proxy and not a web server for serving static files, we replaced nginx with **Caddy**, a modern, lightweight web server that's perfect for serving static files and has a simpler configuration.

#### Client Changes (`k8s/client/`)
- **Removed**: `nginx.conf` (nginx configuration)
- **Added**: `Caddyfile` (Caddy configuration)
- **Modified**: `Dockerfile` - Changed from `nginx:alpine` base to `caddy:2-alpine`

The client Caddyfile provides:
- Static file serving from `/usr/share/caddy`
- Gzip compression
- SPA (Single Page Application) routing with fallback to `index.html`
- Cache headers for static assets
- Security headers (X-Frame-Options, X-Content-Type-Options, X-XSS-Protection)

#### Server Changes (`k8s/server/`)
- **Removed**: `server-nginx.conf` (nginx configuration), `start.sh` (startup script)
- **Added**: `Caddyfile` (Caddy configuration)
- **Modified**: `Dockerfile` - Changed from `node:18-alpine` + nginx to `caddy:2-alpine`

The server Caddyfile provides:
- File serving from `/data/excalidraw` with directory browsing
- CORS headers for cross-origin access
- JSON content-type for `.excalidraw` files
- File upload support endpoint
- OPTIONS request handling for CORS preflight

### 2. Ingress Controller (nginx-ingress → Traefik)

Updated the ingress configuration to use Traefik annotations instead of nginx annotations.

#### Changes in `k8s/base/ingress.yaml`
- **Removed**: nginx-specific annotations
- **Added**: Traefik annotations:
  - `traefik.ingress.kubernetes.io/router.entrypoints: web`
  - Comments for HTTPS/TLS configuration

### 3. Documentation Updates

Updated all documentation files to reflect the new architecture:

- **README.md**: Updated architecture description, prerequisites, and directory structure
- **ARCHITECTURE.md**: Updated component details, technology stack, and data flow diagrams
- **DEPLOYMENT_SUMMARY.md**: Updated directory structure and key features
- **QUICKSTART.md**: Changed ingress controller check from `ingress-nginx` to `traefik`
- **한국어_가이드.md**: Updated Korean documentation with new file structure

## Benefits of This Migration

### Why Caddy?
1. **Simpler Configuration**: Caddyfile is more readable and maintainable than nginx.conf
2. **Modern Features**: Built-in HTTP/2, automatic HTTPS (when needed), and modern security defaults
3. **Lightweight**: Similar resource footprint to nginx in Alpine
4. **Better Defaults**: Sensible security and performance defaults out of the box

### Why Traefik?
1. **Kubernetes Native**: Better integration with Kubernetes resources
2. **Dynamic Configuration**: Automatically discovers services and routes
3. **Modern Protocol Support**: HTTP/2, gRPC, WebSocket support
4. **Built-in Let's Encrypt**: Easy TLS certificate management
5. **Rich Middleware**: Extensive middleware options for headers, auth, rate limiting, etc.

## Prerequisites After Migration

Users will need:
- Traefik ingress controller installed in the Kubernetes cluster (instead of nginx-ingress)
- Docker images rebuilt with the new Dockerfiles
- No other changes to the Kubernetes deployment manifests are required

## Testing

The Caddyfile configurations have been validated using:
```bash
docker run --rm -v $(pwd)/k8s/client/Caddyfile:/etc/caddy/Caddyfile caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile
docker run --rm -v $(pwd)/k8s/server/Caddyfile:/etc/caddy/Caddyfile caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile
```

Both configurations are valid and ready for deployment.

## Deployment Notes

1. **Build Images**: Run `./build.sh` to rebuild Docker images with Caddy
2. **Deploy**: Follow the normal deployment process in README.md
3. **Traefik Setup**: Ensure Traefik is installed as the ingress controller in your cluster

## Compatibility

This migration maintains:
- ✅ Same port numbers (80 for client, 8080 for server)
- ✅ Same functionality (static file serving, CORS, directory listing)
- ✅ Same deployment structure and order
- ✅ Same service definitions
- ✅ Same ingress path routing

The changes are transparent to end users - the application behavior remains identical.

## Rollback

If needed, the previous nginx-based configuration is available in the git history. To rollback:
```bash
git revert <commit-hash>
```
