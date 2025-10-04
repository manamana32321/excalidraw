# Excalidraw Socket Server Dockerfile
FROM node:18-alpine

WORKDIR /app

# Clone Excalidraw repository and build socket server
RUN apk add --no-cache git && \
    git clone https://github.com/excalidraw/excalidraw.git . && \
    cd excalidraw-room && \
    yarn install && \
    yarn build

WORKDIR /app/excalidraw-room

EXPOSE 3002

CMD ["yarn", "start"]
