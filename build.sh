#!/bin/bash

# Build script for Excalidraw Kubernetes deployment

set -e

echo "Building Excalidraw Docker images..."

# Build client image
echo "Building client image..."
cd k8s/client
docker build -t excalidraw-client:latest .
cd ../..

# Build server image
echo "Building server image..."
cd k8s/server
docker build -t excalidraw-server:latest .
cd ../..

# Build socket server image (optional)
echo "Building socket server image (optional)..."
cd k8s/socket
docker build -t excalidraw-socket:latest .
cd ../..

echo "All images built successfully!"
echo ""
echo "To deploy to Kubernetes:"
echo "  kubectl apply -k k8s/base/"
echo ""
echo "To enable socket server, uncomment the lines in k8s/base/kustomization.yaml"
