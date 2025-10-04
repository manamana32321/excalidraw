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
FROM nginx:alpine

# Copy built files from builder
COPY --from=builder /app/excalidraw-app/build /usr/share/nginx/html

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
