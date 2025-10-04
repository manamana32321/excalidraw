# Excalidraw Storage Server Dockerfile
FROM caddy:2-alpine

WORKDIR /app

# Create directory for storing excalidraw files
RUN mkdir -p /data/excalidraw

# Copy Caddyfile configuration for serving files
COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 8080

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
