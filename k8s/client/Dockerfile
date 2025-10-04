# Excalidraw Client Dockerfile
FROM node:18-alpine as builder

# Set working directory
WORKDIR /app

# Clone Excalidraw repository
RUN apk add --no-cache git && \
    git clone https://github.com/excalidraw/excalidraw.git . && \
    yarn install && \
    yarn build:app:docker

# Production stage
FROM caddy:2-alpine

# Copy built files from builder
COPY --from=builder /app/excalidraw-app/build /usr/share/caddy

# Copy Caddyfile configuration
COPY Caddyfile /etc/caddy/Caddyfile

EXPOSE 80

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile"]
