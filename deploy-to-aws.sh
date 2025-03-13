#!/bin/bash
# AWS EKS Deployment Script for TruVoice App
# This script helps deploy the TruVoice application to AWS EKS using free tier resources

set -e  # Exit on error

# Replace these variables with your own values
AWS_REGION="us-east-1"
EKS_CLUSTER_NAME="truvoice-cluster"
ECR_REPOSITORY_NAME="truvoice"

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment process for TruVoice to AWS EKS...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI not found. Please install it first: https://aws.amazon.com/cli/${NC}"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker not found. Please install it first: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl not found. Please install it first: https://kubernetes.io/docs/tasks/tools/${NC}"
    exit 1
fi

# Check if eksctl is installed
if ! command -v eksctl &> /dev/null; then
    echo -e "${RED}eksctl not found. Please install it first: https://eksctl.io/installation/${NC}"
    exit 1
fi

# 1. Configure AWS CLI
echo -e "${YELLOW}1. Configuring AWS CLI...${NC}"
echo -e "${YELLOW}   Please enter your AWS credentials:${NC}"
aws configure

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
echo -e "${GREEN}   AWS account ID: ${AWS_ACCOUNT_ID}${NC}"

# 2. Create ECR repository
echo -e "${YELLOW}2. Creating ECR repository...${NC}"
aws ecr describe-repositories --repository-names ${ECR_REPOSITORY_NAME} > /dev/null 2>&1 || aws ecr create-repository --repository-name ${ECR_REPOSITORY_NAME}
echo -e "${GREEN}   ECR repository created/confirmed: ${ECR_REPOSITORY_NAME}${NC}"

# 3. Login to ECR
echo -e "${YELLOW}3. Logging in to ECR...${NC}"
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
echo -e "${GREEN}   Successfully logged in to ECR${NC}"

# 4. Build Docker image
echo -e "${YELLOW}4. Building Docker image...${NC}"
docker build -t ${ECR_REPOSITORY_NAME}:latest .
echo -e "${GREEN}   Docker image built successfully${NC}"

# 5. Tag and push Docker image to ECR
echo -e "${YELLOW}5. Tagging and pushing Docker image to ECR...${NC}"
docker tag ${ECR_REPOSITORY_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY_NAME}:latest
echo -e "${GREEN}   Docker image pushed to ECR successfully${NC}"

# 6. Create EKS cluster (using minimal free-tier compatible resources)
echo -e "${YELLOW}6. Creating EKS cluster (this may take 15-20 minutes)...${NC}"
eksctl create cluster \
    --name ${EKS_CLUSTER_NAME} \
    --region ${AWS_REGION} \
    --node-type t3.small \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 3 \
    --managed
echo -e "${GREEN}   EKS cluster created successfully${NC}"

# 7. Update kubeconfig
echo -e "${YELLOW}7. Updating kubeconfig...${NC}"
aws eks update-kubeconfig --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}
echo -e "${GREEN}   kubeconfig updated successfully${NC}"

# 8. Update image repository in deployment.yaml
echo -e "${YELLOW}8. Updating image repository in deployment.yaml...${NC}"
sed -i "s/\${AWS_ACCOUNT_ID}/${AWS_ACCOUNT_ID}/g" k8s/deployment.yaml
sed -i "s/\${AWS_REGION}/${AWS_REGION}/g" k8s/deployment.yaml
echo -e "${GREEN}   deployment.yaml updated successfully${NC}"

# 9. Update truvoice-secrets.yaml with actual values
echo -e "${YELLOW}9. Updating secrets with actual values...${NC}"
echo -e "${YELLOW}   IMPORTANT: Replace placeholder values in k8s/secrets.yaml with your actual secrets.${NC}"
echo -e "${YELLOW}   After updating, run: kubectl apply -f k8s/secrets.yaml${NC}"
echo -e "${YELLOW}   Press Enter to continue when ready...${NC}"
read -p ""

# 10. Apply Kubernetes manifests
echo -e "${YELLOW}10. Applying Kubernetes manifests...${NC}"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
echo -e "${GREEN}   Kubernetes manifests applied successfully${NC}"

# 11. Check deployment status
echo -e "${YELLOW}11. Checking deployment status...${NC}"
kubectl get pods
kubectl get services
kubectl get ingress
echo -e "${GREEN}   Deployment completed successfully!${NC}"

echo -e "${YELLOW}IMPORTANT NOTES:${NC}"
echo -e "${YELLOW}- Configure a domain name and point it to the ALB created by the ingress controller${NC}"
echo -e "${YELLOW}- Update NEXTAUTH_URL in the deployment.yaml with your actual domain${NC}"
echo -e "${YELLOW}- Monitor the resources to stay within AWS Free Tier limits${NC}"
echo -e "${YELLOW}- To destroy the infrastructure when not needed, run:${NC}"
echo -e "${YELLOW}  eksctl delete cluster --name ${EKS_CLUSTER_NAME} --region ${AWS_REGION}${NC}"
echo -e "${YELLOW}  aws ecr delete-repository --repository-name ${ECR_REPOSITORY_NAME} --force${NC}"

echo -e "${GREEN}Thank you for using TruVoice deployment script!${NC}" 