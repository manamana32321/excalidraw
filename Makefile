.PHONY: help deploy clean status logs check-prereq

# Default target
help:
	@echo "Excalidraw Kubernetes Deployment"
	@echo "================================="
	@echo ""
	@echo "Available targets:"
	@echo "  make check-prereq    - Check prerequisites (kubectl)"
	@echo "  make deploy          - Deploy to Kubernetes"
	@echo "  make deploy-client   - Deploy client only"
	@echo "  make deploy-server   - Deploy server only"
	@echo "  make deploy-socket   - Deploy socket server"
	@echo "  make deploy-kustomize - Deploy using Kustomize"
	@echo "  make status          - Show deployment status"
	@echo "  make logs            - Show logs from all pods"
	@echo "  make logs-client     - Show client logs"
	@echo "  make logs-server     - Show server logs"
	@echo "  make logs-socket     - Show socket logs"
	@echo "  make clean           - Delete all resources"
	@echo "  make validate        - Validate YAML files"
	@echo ""

# Check prerequisites
check-prereq:
	@echo "Checking prerequisites..."
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed"; exit 1; }
	@echo "✓ kubectl found"
	@kubectl cluster-info >/dev/null 2>&1 && echo "✓ kubectl can access cluster" || { echo "✗ Cannot access Kubernetes cluster"; exit 1; }

# Deploy targets
deploy: check-prereq
	@echo "Deploying Excalidraw..."
	@./deploy.sh

deploy-client: check-prereq
	@echo "Deploying client..."
	@kubectl apply -f k8s/base/namespace.yaml
	@kubectl apply -f k8s/client/deployment.yaml
	@kubectl apply -f k8s/client/service.yaml

deploy-server: check-prereq
	@echo "Deploying server..."
	@kubectl apply -f k8s/base/namespace.yaml
	@kubectl apply -f k8s/base/pvc.yaml
	@kubectl apply -f k8s/base/configmap.yaml
	@kubectl apply -f k8s/server/deployment.yaml
	@kubectl apply -f k8s/server/service.yaml

deploy-socket: check-prereq
	@echo "Deploying socket server..."
	@kubectl apply -f k8s/socket/deployment.yaml
	@kubectl apply -f k8s/socket/service.yaml

deploy-ingress: check-prereq
	@echo "Deploying ingress..."
	@kubectl apply -f k8s/base/ingress.yaml

deploy-kustomize: check-prereq
	@echo "Deploying with Kustomize..."
	@kubectl apply -k k8s/base/

# Status and logs
status: check-prereq
	@echo "=== Namespace ==="
	@kubectl get namespace excalidraw 2>/dev/null || echo "Namespace not found"
	@echo ""
	@echo "=== Deployments ==="
	@kubectl get deployments -n excalidraw 2>/dev/null || echo "No deployments found"
	@echo ""
	@echo "=== Pods ==="
	@kubectl get pods -n excalidraw 2>/dev/null || echo "No pods found"
	@echo ""
	@echo "=== Services ==="
	@kubectl get services -n excalidraw 2>/dev/null || echo "No services found"
	@echo ""
	@echo "=== Ingress ==="
	@kubectl get ingress -n excalidraw 2>/dev/null || echo "No ingress found"
	@echo ""
	@echo "=== PVC ==="
	@kubectl get pvc -n excalidraw 2>/dev/null || echo "No PVC found"

logs: check-prereq
	@echo "=== Client Logs ==="
	@kubectl logs -n excalidraw deployment/excalidraw-client --tail=50 2>/dev/null || echo "Client not deployed"
	@echo ""
	@echo "=== Server Logs ==="
	@kubectl logs -n excalidraw deployment/excalidraw-server --tail=50 2>/dev/null || echo "Server not deployed"
	@echo ""
	@echo "=== Socket Logs ==="
	@kubectl logs -n excalidraw deployment/excalidraw-socket --tail=50 2>/dev/null || echo "Socket not deployed"

logs-client: check-prereq
	@kubectl logs -n excalidraw deployment/excalidraw-client -f

logs-server: check-prereq
	@kubectl logs -n excalidraw deployment/excalidraw-server -f

logs-socket: check-prereq
	@kubectl logs -n excalidraw deployment/excalidraw-socket -f

# Validation
validate:
	@echo "Validating YAML files..."
	@for file in $$(find k8s -name "*.yaml"); do \
		echo "Checking $$file..."; \
		python3 -c "import yaml; yaml.safe_load(open('$$file'))" && echo "✓ Valid" || echo "✗ Invalid"; \
	done

# Clean up
clean: check-prereq
	@echo "Deleting Excalidraw resources..."
	@kubectl delete namespace excalidraw 2>/dev/null || echo "Namespace already deleted"
	@echo "Cleanup complete"

# Restart deployments
restart: check-prereq
	@echo "Restarting all deployments..."
	@kubectl rollout restart deployment -n excalidraw

restart-client: check-prereq
	@kubectl rollout restart deployment/excalidraw-client -n excalidraw

restart-server: check-prereq
	@kubectl rollout restart deployment/excalidraw-server -n excalidraw

restart-socket: check-prereq
	@kubectl rollout restart deployment/excalidraw-socket -n excalidraw

# Port forwarding for local testing
port-forward-client:
	@echo "Forwarding client to http://localhost:8080"
	@kubectl port-forward -n excalidraw service/excalidraw-client 8080:80

port-forward-server:
	@echo "Forwarding server to http://localhost:8081"
	@kubectl port-forward -n excalidraw service/excalidraw-server 8081:8080

port-forward-socket:
	@echo "Forwarding socket to http://localhost:3002"
	@kubectl port-forward -n excalidraw service/excalidraw-socket 3002:3002

# Describe resources
describe-client:
	@kubectl describe deployment/excalidraw-client -n excalidraw

describe-server:
	@kubectl describe deployment/excalidraw-server -n excalidraw

describe-socket:
	@kubectl describe deployment/excalidraw-socket -n excalidraw

describe-ingress:
	@kubectl describe ingress/excalidraw-ingress -n excalidraw

# Get ingress info
ingress-info:
	@echo "=== Ingress Information ==="
	@kubectl get ingress excalidraw-ingress -n excalidraw -o wide
	@echo ""
	@echo "Configure your DNS to point to the ADDRESS shown above"
