# Excalidraw Socket Server Dockerfile
# Multi-stage build for optimized production image

# Build stage
FROM node:18-alpine as builder

WORKDIR /app

# Clone Excalidraw repository and build socket server
RUN apk add --no-cache git && \
    git clone https://github.com/excalidraw/excalidraw.git . && \
    cd excalidraw-room && \
    yarn install && \
    yarn build

# Production stage
FROM node:18-alpine

WORKDIR /app/excalidraw-room

# Copy built files and package files from builder
COPY --from=builder /app/excalidraw-room/dist ./dist
COPY --from=builder /app/excalidraw-room/package.json ./package.json
COPY --from=builder /app/excalidraw-room/yarn.lock ./yarn.lock

# Install production dependencies only
RUN yarn install --production --frozen-lockfile && \
    yarn cache clean

EXPOSE 3002

CMD ["yarn", "start"]
