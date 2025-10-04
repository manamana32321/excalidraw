# Excalidraw Storage Server Dockerfile
FROM node:18-alpine

WORKDIR /app

# Install dependencies
RUN apk add --no-cache nginx

# Create directory for storing excalidraw files
RUN mkdir -p /data/excalidraw

# Copy nginx configuration for serving files
COPY server-nginx.conf /etc/nginx/http.d/default.conf

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 8080

CMD ["/app/start.sh"]
