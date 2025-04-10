# TruVoice Kubernetes Deployment Guide

This guide provides comprehensive instructions for deploying the TruVoice application on Kubernetes.

## Prerequisites

- Kubernetes cluster (K3s or similar)
- AWS CLI configured with appropriate credentials
- `kubectl` command-line tool
- Access to AWS ECR (Elastic Container Registry)
- MongoDB Atlas account
- Google Cloud Platform account (for OAuth)
- Gemini API key

## Directory Structure

```
k8s/
├── deployment.yaml      # Main application deployment
├── service.yaml         # Kubernetes service
├── ingress.yaml         # ALB ingress configuration
├── secrets.yaml         # Secrets template
├── ecr-secret-template.txt  # ECR authentication template
└── monitoring/          # Monitoring stack configuration
    └── README.md        # Monitoring setup instructions
```

## Configuration Files

### 1. Secrets Configuration

Before deploying, you need to set up the following secrets:

1. Create a `secrets.yaml` file based on the template:
   ```bash
   cp secrets.yaml.template secrets.yaml
   ```

2. Update the following secrets in `secrets.yaml`:
   - `mongodb-uri`: Your MongoDB Atlas connection string
   - `nextauth-secret`: A secure random string for NextAuth
   - `gemini-api-key`: Your Google Gemini API key
   - `client-id`: Google OAuth client ID
   - `client-secret`: Google OAuth client secret
   - `redirect-uri`: OAuth redirect URI
   - `refresh-token`: Google OAuth refresh token
   - `email`: Application email address

3. Apply the secrets:
   ```bash
   kubectl apply -f secrets.yaml
   ```

### 2. ECR Authentication

1. Create the ECR secret using the template:
   ```bash
   kubectl create secret docker-registry ecr-secret \
     --docker-server=730335582131.dkr.ecr.us-east-1.amazonaws.com \
     --docker-username=AWS \
     --docker-password=$(aws ecr get-login-password --region us-east-1)
   ```

### 3. Application Deployment

The application deployment (`deployment.yaml`) includes:
- Resource limits and requests
- Environment variables
- Health checks
- Container configuration

Key features:
- Resource limits: 0.5 CPU, 512Mi memory
- Resource requests: 0.25 CPU, 256Mi memory
- Liveness and readiness probes on `/api/health`
- Automatic image pull policy

### 4. Service Configuration

The service (`service.yaml`) exposes:
- Port 80 externally
- Port 3000 internally
- Prometheus metrics annotations
- ClusterIP type (for internal access)

### 5. Ingress Configuration

The ingress (`ingress.yaml`) configures:
- ALB ingress controller
- Internet-facing scheme
- IP target type
- Host-based routing

## Deployment Steps

1. **Create Namespace** (if not exists):
   ```bash
   kubectl create namespace truvoice
   ```

2. **Apply Secrets**:
   ```bash
   kubectl apply -f secrets.yaml
   ```

3. **Apply ECR Secret**:
   ```bash
   kubectl apply -f ecr-secret.yaml
   ```

4. **Deploy Application**:
   ```bash
   kubectl apply -f deployment.yaml
   ```

5. **Create Service**:
   ```bash
   kubectl apply -f service.yaml
   ```

6. **Configure Ingress**:
   ```bash
   kubectl apply -f ingress.yaml
   ```

## Monitoring Setup

For monitoring setup, refer to the [Monitoring README](monitoring/README.md) which includes:
- Prometheus configuration
- Grafana setup
- Metrics collection
- Dashboard configuration

## Verification Steps

1. **Check Pod Status**:
   ```bash
   kubectl get pods -l app=truvoice
   ```

2. **Verify Service**:
   ```bash
   kubectl get svc truvoice-service
   ```

3. **Check Ingress**:
   ```bash
   kubectl get ingress truvoice-ingress
   ```

4. **Test Application**:
   ```bash
   curl http://44.192.70.116/api/health
   ```

## Troubleshooting

1. **Pod Issues**:
   ```bash
   kubectl describe pod -l app=truvoice
   kubectl logs -l app=truvoice
   ```

2. **Service Issues**:
   ```bash
   kubectl describe svc truvoice-service
   ```

3. **Ingress Issues**:
   ```bash
   kubectl describe ingress truvoice-ingress
   ```

4. **Secret Issues**:
   ```bash
   kubectl get secrets
   kubectl describe secret truvoice-secrets
   ```

## Resource Management

The deployment is configured with the following resources:
- CPU Limit: 0.5 cores
- Memory Limit: 512Mi
- CPU Request: 0.25 cores
- Memory Request: 256Mi

Adjust these values based on your cluster's capacity and requirements.

## Security Considerations

1. **Secrets Management**:
   - Never commit actual secrets to version control
   - Use a secrets management solution in production
   - Rotate secrets regularly

2. **Network Security**:
   - Configure appropriate network policies
   - Use TLS for external access
   - Implement proper authentication

3. **Container Security**:
   - Regular security updates
   - Image scanning
   - Least privilege principle

## Maintenance

1. **Updates**:
   ```bash
   kubectl set image deployment/truvoice-app truvoice=730335582131.dkr.ecr.us-east-1.amazonaws.com/truvoice:new-tag
   ```

2. **Scaling**:
   ```bash
   kubectl scale deployment truvoice-app --replicas=2
   ```

3. **Rollbacks**:
   ```bash
   kubectl rollout undo deployment/truvoice-app
   ```

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review application logs
3. Check monitoring dashboards
4. Contact the development team

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [MongoDB Atlas Documentation](https://docs.atlas.mongodb.com/)
- [NextAuth.js Documentation](https://next-auth.js.org/) 