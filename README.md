# TruVoice Kubernetes Deployment

This repository contains the necessary Kubernetes configuration files for deploying the TruVoice application using AWS ECR and Kubernetes.

## Live Demo

- **URL**: [http://44.192.70.116/](http://44.192.70.116/)

## Deployment Files

- `k8s/deployment.yaml` - Application deployment configuration
- `k8s/service.yaml` - Service configuration for external access
- `k8s/ingress.yaml` - Ingress configuration
- `k8s/secrets.yaml` - Template for application secrets
- `k8s/ecr-secret.yaml` - Configuration for ECR authentication

## Quick Deployment Steps

### 1. Create ECR Secret

Run the following command to create a secret for ECR authentication:

```bash
kubectl create secret docker-registry ecr-secret \
  --docker-server=<aws-account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  --dry-run=client -o yaml > k8s/ecr-secret.yaml

kubectl apply -f k8s/ecr-secret.yaml
```

### 2. Apply Kubernetes Resources

```bash
# Apply secrets first
kubectl apply -f k8s/secrets.yaml

# Apply other resources
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

### 3. Set Up Port Forwarding (if needed)

```bash
NODE_PORT=$(kubectl get svc truvoice-service -o jsonpath='{.spec.ports[0].nodePort}')
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $NODE_PORT
```

## Updating the Application

To update the application to a new version:

```bash
# Push new image to ECR (from your local machine)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/truvoice:latest .
docker push <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com/truvoice:latest

# Restart the deployment (on the k3s server)
kubectl rollout restart deployment/truvoice-app
```

## Monitoring

```bash
# Check pod status
kubectl get pods

# View logs
kubectl logs -f $(kubectl get pods -l app=truvoice -o jsonpath='{.items[0].metadata.name}')

# Check service
kubectl get svc truvoice-service
```

## Environment Variables

Update `k8s/secrets.yaml` with your actual credentials:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: truvoice-secrets
type: Opaque
stringData:
  mongodb-uri: "your-mongodb-uri"
  nextauth-secret: "your-nextauth-secret"
  gemini-api-key: "your-gemini-api-key"
  client-id: "your-client-id"
  client-secret: "your-client-secret"
  redirect-uri: "your-redirect-uri"
  refresh-token: "your-refresh-token"
  email: "your-email"
```
---

