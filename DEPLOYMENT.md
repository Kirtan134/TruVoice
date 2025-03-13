# TruVoice Application Deployment Guide

This guide provides instructions for deploying the TruVoice application using Docker and Kubernetes on AWS Free Tier.

## Prerequisites

Before proceeding with the deployment, ensure you have the following prerequisites:

1. An AWS account with Free Tier eligibility
2. AWS CLI installed and configured
3. Docker installed on your local machine
4. kubectl command-line tool installed
5. eksctl command-line tool installed

## AWS Services Used (Free Tier Eligible)

- **Amazon ECR** - For storing Docker images
- **Amazon EKS** - For orchestrating Kubernetes
- **Amazon EC2** - For running the application (t3.small instances)
- **Amazon VPC** - For network isolation
- **Application Load Balancer** - For routing traffic

## Deployment Steps

### 1. Repository Setup

Clone the repository and navigate to the project directory:

```bash
git clone https://github.com/your-username/truvoice.git
cd truvoice
```

### 2. Environment Configuration

Create a `.env.production` file based on your `.env` file but with production-ready values:

```
NEXTAUTH_SECRET=your-production-secret
MONGODB_URI=your-production-mongodb-uri
GEMINI_API_KEY=your-production-api-key
CLIENT_ID=your-production-client-id
CLIENT_SECRET=your-production-client-secret
REDIRECT_URI=your-production-redirect-uri
REFRESH_TOKEN=your-production-refresh-token
EMAIL=your-production-email
NEXTAUTH_URL=https://your-domain.com
```

### 3. Kubernetes Secret Configuration

Update the secrets in `k8s/secrets.yaml` with your production values:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: truvoice-secrets
type: Opaque
stringData:
  mongodb-uri: "your-production-mongodb-uri"
  nextauth-secret: "your-production-secret"
  gemini-api-key: "your-production-api-key"
  client-id: "your-production-client-id"
  client-secret: "your-production-client-secret"
  redirect-uri: "your-production-redirect-uri"
  refresh-token: "your-production-refresh-token"
  email: "your-production-email"
```

### 4. Update Deployment Configuration

In `k8s/deployment.yaml` and `k8s/ingress.yaml`, replace `truvoice.example.com` with your actual domain name.

### 5. Automated Deployment

Make the deployment script executable and run it:

```bash
chmod +x deploy-to-aws.sh
./deploy-to-aws.sh
```

The script will guide you through the deployment process, including:
- Setting up AWS credentials
- Creating an ECR repository
- Building and pushing the Docker image
- Creating an EKS cluster
- Deploying the application to Kubernetes

### 6. Manual Deployment (Alternative)

If you prefer to deploy manually, follow these steps:

1. **Build and Push Docker Image**

   ```bash
   # Login to Amazon ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
   
   # Build Docker image
   docker build -t truvoice:latest .
   
   # Tag the image
   docker tag truvoice:latest YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/truvoice:latest
   
   # Push image to ECR
   docker push YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/truvoice:latest
   ```

2. **Create EKS Cluster**

   ```bash
   eksctl create cluster \
     --name truvoice-cluster \
     --region us-east-1 \
     --node-type t3.small \
     --nodes 2 \
     --nodes-min 1 \
     --nodes-max 3 \
     --managed
   ```

3. **Deploy to Kubernetes**

   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --name truvoice-cluster --region us-east-1
   
   # Apply Kubernetes manifests
   kubectl apply -f k8s/secrets.yaml
   kubectl apply -f k8s/deployment.yaml
   kubectl apply -f k8s/service.yaml
   kubectl apply -f k8s/ingress.yaml
   ```

## Staying Within Free Tier Limits

To ensure you stay within AWS Free Tier limits:

1. **Use t3.small instances**: These are eligible for AWS Free Tier, but limit the number to 1-2 instances.
2. **Monitor usage**: Set up AWS Budgets to monitor your usage and costs.
3. **Scale down when not in use**: You can scale down the cluster to 0 nodes when not in use.
4. **Delete resources**: When you no longer need them, delete all resources:

   ```bash
   # Delete EKS cluster
   eksctl delete cluster --name truvoice-cluster --region us-east-1
   
   # Delete ECR repository
   aws ecr delete-repository --repository-name truvoice --force
   ```

## Health Checks

The application includes a health check endpoint at `/api/health` that returns:

```json
{
  "status": "ok",
  "timestamp": "2023-07-25T12:00:00.000Z"
}
```

This endpoint is used for Kubernetes liveness and readiness probes.

## Troubleshooting

1. **Pod Startup Issues**: Check pod logs with `kubectl logs -f [pod-name]`
2. **Connection Issues**: Ensure security groups allow traffic to the ALB
3. **Database Connectivity**: Verify MongoDB URI is correctly set in secrets
4. **Authentication Issues**: Check that all OAuth credentials are correctly configured

## Additional Resources

- [AWS Free Tier Documentation](https://aws.amazon.com/free/)
- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Docker Documentation](https://docs.docker.com/)

For any issues or questions, please open an issue in the GitHub repository. 