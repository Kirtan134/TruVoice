# TruVoice Kubernetes Deployment

This repository contains the Kubernetes configuration files for deploying the TruVoice application - an anonymous feedback platform with AI integration, using AWS ECR and Kubernetes (k3s) on AWS Free Tier resources.

## Live Demo

- **Live Demo URL**: [Truvoice](http://3.110.219.229:32233/)
- **GitHub Repository**: [https://github.com/Kirtan134/TruVoice/tree/deployment](https://github.com/Kirtan134/TruVoice/tree/deployment)

## Architecture Overview

This deployment uses a lightweight Kubernetes architecture:

- **Infrastructure**: AWS EC2 t2.micro instance (Free Tier eligible)
- **Container Orchestration**: k3s (lightweight Kubernetes)
- **Container Registry**: AWS ECR (Elastic Container Registry)
- **Application**: Next.js-based TruVoice app
- **Database**: MongoDB Atlas (external)
- **Authentication**: NextAuth.js with JWT tokens
- **AI Integration**: Gemini AI API

## Deployment Files

- **Application**
  - `Dockerfile` - Multi-stage build for the Next.js application
  
- **Kubernetes Resources**
  - `k8s/deployment.yaml` - Application deployment configuration
  - `k8s/service.yaml` - Service configuration for external access
  - `k8s/ingress.yaml` - Ingress configuration
  - `k8s/secrets.yaml` - Template for application secrets
  - `k8s/ecr-secret-template.txt` - Reference for creating ECR auth secret

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with ECR repository created
2. **Docker** installed on your local machine
3. **kubectl** configured to connect to your Kubernetes cluster
4. **Kubernetes Cluster** (k3s) running on an EC2 instance
5. **MongoDB Atlas** account with a database set up
6. **Gemini AI API key** for AI integration

## Deployment Guide

### 1. Configure AWS ECR

If you haven't already created an ECR repository:

```bash
# Create ECR repository
aws ecr create-repository --repository-name truvoice
```

### 2. Build and Push Docker Image

```bash
# Build and tag the image
docker build -t truvoice:latest .
docker tag truvoice:latest YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/truvoice:latest

# Login to ECR
aws ecr get-login-password --region YOUR_REGION | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com

# Push the image
docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/truvoice:latest
```

### 3. Create Kubernetes Secrets

#### a. Create ECR Authentication Secret

Run this command directly on your Kubernetes cluster:

```bash
# Create secret for ECR authentication
kubectl create secret docker-registry ecr-secret \
  --docker-server=YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region YOUR_REGION)
```

#### b. Create Application Secrets

Create a file named `k8s/secrets.yaml` (don't commit this to Git):

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

Apply the secrets:

```bash
kubectl apply -f k8s/secrets.yaml
```

### 4. Deploy Kubernetes Resources

```bash
# Apply deployment, service, and ingress
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
```

### 5. Configure Port Forwarding

If your service is using NodePort (typical for k3s on a single instance), set up port forwarding:

```bash
# Get the NodePort assigned to your service
NODE_PORT=$(kubectl get svc truvoice-service -o jsonpath='{.spec.ports[0].nodePort}')

# Set up port forwarding from port 80 to NodePort
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $NODE_PORT

# Make the port forwarding persistent (survives reboots)
sudo apt-get install iptables-persistent -y
sudo netfilter-persistent save
```

## Managing Your Deployment

### Updating the Application

When you make changes to your application:

```bash
# Build and push new image
docker build -t YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/truvoice:latest .
docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/truvoice:latest

# Restart the deployment to pick up the new image
kubectl rollout restart deployment/truvoice-app

# Monitor the rollout
kubectl rollout status deployment/truvoice-app
```

### Scaling the Application

```bash
# Scale to more replicas (if needed)
kubectl scale deployment/truvoice-app --replicas=2

# Note: For free tier, keep this at 1 to stay within resource limits
```

### Monitoring

#### View Resources

```bash
# List all resources
kubectl get all

# Check pods status
kubectl get pods

# Check deployment details
kubectl describe deployment truvoice-app
```

#### Logs and Debugging

```bash
# View logs for a pod
kubectl logs -f $(kubectl get pods -l app=truvoice -o jsonpath='{.items[0].metadata.name}')

# Get details of a pod
kubectl describe pod $(kubectl get pods -l app=truvoice -o jsonpath='{.items[0].metadata.name}')

# Check service configuration
kubectl get svc truvoice-service -o yaml
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Image Pull Error

If pods show `ImagePullBackOff`:

```bash
# Check if ECR secret is correct
kubectl get secret ecr-secret -o yaml

# Re-create ECR secret if needed
kubectl delete secret ecr-secret
kubectl create secret docker-registry ecr-secret \
  --docker-server=YOUR_AWS_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region YOUR_REGION)
```

#### 2. Application Not Starting

If the pods are running but the application isn't accessible:

```bash
# Check pod logs
kubectl logs -f $(kubectl get pods -l app=truvoice -o jsonpath='{.items[0].metadata.name}')

# Check if NodePort is configured correctly
kubectl get svc truvoice-service

# Verify port forwarding
sudo iptables -t nat -L PREROUTING
```

#### 3. Environment Variables Missing

If your application can't connect to external services:

```bash
# Check if secrets are mounted correctly
kubectl describe pod $(kubectl get pods -l app=truvoice -o jsonpath='{.items[0].metadata.name}')

# Verify the environment variables in the container
kubectl exec -it $(kubectl get pods -l app=truvoice -o jsonpath='{.items[0].metadata.name}') -- env
```

## Security Considerations

1. **Never commit secrets to Git**
   - Use `.gitignore` to exclude sensitive files
   - Create secrets directly on your cluster

2. **Secure ECR Access**
   - Use IAM roles with least privilege
   - Regularly rotate credentials

3. **Update Dependencies**
   - Regularly update your application dependencies
   - Scan Docker images for vulnerabilities

## AWS Free Tier Considerations

- **EC2 Instance**: t2.micro has 750 hours/month free (enough for 1 instance running 24/7)
- **ECR Storage**: 500MB of storage for private repositories is free
- **Data Transfer**: 100GB/month of outbound data is free

Monitor your AWS usage to avoid unexpected charges.

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [k3s Documentation](https://docs.k3s.io/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [Next.js Deployment Documentation](https://nextjs.org/docs/deployment)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributors

- Kirtan Parikh (@Kirtan134)
---

