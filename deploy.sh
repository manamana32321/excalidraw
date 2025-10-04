#!/bin/bash

# Deploy script for Excalidraw to Kubernetes

set -e

echo "Deploying Excalidraw to Kubernetes..."

# Create namespace
echo "Creating namespace..."
kubectl apply -f k8s/base/namespace.yaml

# Deploy base resources
echo "Deploying base resources..."
kubectl apply -k k8s/base/

# Wait for deployments
echo "Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/excalidraw-client -n excalidraw
kubectl wait --for=condition=available --timeout=300s deployment/excalidraw-server -n excalidraw

echo ""
echo "Deployment completed successfully!"
echo ""
echo "To check the status:"
echo "  kubectl get all -n excalidraw"
echo ""
echo "To access the application, configure your DNS to point to the ingress IP:"
echo "  kubectl get ingress -n excalidraw"
