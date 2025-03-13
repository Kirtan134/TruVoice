#!/bin/bash
# TruVoice EC2 Deployment Script - AWS Free Tier Compatible
# This script helps deploy the TruVoice application to a single EC2 instance

set -e  # Exit on error

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment process for TruVoice to AWS EC2 (Free Tier)...${NC}"

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

# 1. Configure AWS CLI
echo -e "${YELLOW}1. Configuring AWS CLI...${NC}"
echo -e "${YELLOW}   Please enter your AWS credentials:${NC}"
aws configure

# Store region and account ID
AWS_REGION=$(aws configure get region)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
ECR_REPOSITORY_NAME="truvoice"

echo -e "${GREEN}   AWS account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}   AWS region: ${AWS_REGION}${NC}"

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

# 6. Create EC2 key pair if needed
EC2_KEY_NAME="truvoice-key"
echo -e "${YELLOW}6. Checking for EC2 key pair...${NC}"
if aws ec2 describe-key-pairs --key-names ${EC2_KEY_NAME} 2>&1 | grep -q "InvalidKeyPair.NotFound"; then
    echo -e "${YELLOW}   Creating new key pair: ${EC2_KEY_NAME}${NC}"
    aws ec2 create-key-pair --key-name ${EC2_KEY_NAME} --query 'KeyMaterial' --output text > ${EC2_KEY_NAME}.pem
    chmod 400 ${EC2_KEY_NAME}.pem
    echo -e "${GREEN}   Key pair created and saved to ${EC2_KEY_NAME}.pem${NC}"
    echo -e "${YELLOW}   IMPORTANT: Keep this file safe. It will be needed to SSH into your instance.${NC}"
else
    echo -e "${GREEN}   Key pair ${EC2_KEY_NAME} already exists${NC}"
fi

# 7. Create security group
SECURITY_GROUP_NAME="truvoice-sg"
echo -e "${YELLOW}7. Setting up security group...${NC}"
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=${SECURITY_GROUP_NAME} --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")

if [ "$SECURITY_GROUP_ID" = "None" ] || [ -z "$SECURITY_GROUP_ID" ]; then
    echo -e "${YELLOW}   Creating new security group: ${SECURITY_GROUP_NAME}${NC}"
    SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name ${SECURITY_GROUP_NAME} --description "Security group for TruVoice application" --query 'GroupId' --output text)
    
    # Allow SSH from current IP
    MY_IP=$(curl -s https://checkip.amazonaws.com)
    aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr ${MY_IP}/32
    
    # Allow HTTP and HTTPS from anywhere
    aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 443 --cidr 0.0.0.0/0
    
    echo -e "${GREEN}   Security group created with ID: ${SECURITY_GROUP_ID}${NC}"
else
    echo -e "${GREEN}   Using existing security group: ${SECURITY_GROUP_ID}${NC}"
fi

# 8. Launch EC2 instance
echo -e "${YELLOW}8. Launching EC2 instance (t2.micro - Free Tier eligible)...${NC}"

# Get latest Amazon Linux 2 AMI ID
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

echo -e "${YELLOW}   Using Amazon Linux 2 AMI: ${AMI_ID}${NC}"

# Create user data script for instance initialization
cat > user-data.sh << 'EOF'
#!/bin/bash
# Initialize instance
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum install -y unzip
unzip awscliv2.zip
./aws/install

# Create a welcome message
echo "TruVoice server setup complete. Run deployment script to complete installation." > /home/ec2-user/welcome.txt
chown ec2-user:ec2-user /home/ec2-user/welcome.txt
EOF

# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ${AMI_ID} \
    --instance-type t2.micro \
    --key-name ${EC2_KEY_NAME} \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --user-data file://user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=TruVoice-Server}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "${GREEN}   EC2 instance launched with ID: ${INSTANCE_ID}${NC}"

# 9. Wait for instance to be running
echo -e "${YELLOW}9. Waiting for instance to be running...${NC}"
aws ec2 wait instance-running --instance-ids ${INSTANCE_ID}

# Get public IP address
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo -e "${GREEN}   Instance is running with public IP: ${PUBLIC_IP}${NC}"

# 10. Create deployment instructions
echo -e "${YELLOW}10. Creating deployment instructions...${NC}"

cat > remote-deploy.sh << EOF
#!/bin/bash
# Remote deployment script for TruVoice on EC2
set -e

# Variables
REGION="${AWS_REGION}"
ACCOUNT_ID="${AWS_ACCOUNT_ID}"
REPO_NAME="${ECR_REPOSITORY_NAME}"
IMAGE_URI="\${ACCOUNT_ID}.dkr.ecr.\${REGION}.amazonaws.com/\${REPO_NAME}:latest"

# Log in to ECR
aws ecr get-login-password --region \${REGION} | docker login --username AWS --password-stdin \${ACCOUNT_ID}.dkr.ecr.\${REGION}.amazonaws.com

# Pull the image
echo "Pulling Docker image..."
docker pull \${IMAGE_URI}

# Stop and remove existing container
echo "Stopping existing container (if running)..."
docker stop truvoice 2>/dev/null || true
docker rm truvoice 2>/dev/null || true

# Run new container
echo "Starting new container..."
docker run -d --name truvoice -p 80:3000 \\
  --restart unless-stopped \\
  --env-file .env.production \\
  \${IMAGE_URI}

echo "Deployment complete! Application is running at http://${PUBLIC_IP}"
EOF

chmod +x remote-deploy.sh

echo -e "${GREEN}   Deployment instructions created in remote-deploy.sh${NC}"

# 11. Create deployment instructions
cat > DEPLOYMENT_INSTRUCTIONS.txt << EOF
========== TRUVOICE EC2 DEPLOYMENT INSTRUCTIONS ==========

Your EC2 instance has been created with IP: ${PUBLIC_IP}

NEXT STEPS:

1. Wait a few minutes for the instance to complete initialization

2. Copy remote-deploy.sh and your environment file to the EC2 instance:
   scp -i ${EC2_KEY_NAME}.pem remote-deploy.sh ec2-user@${PUBLIC_IP}:~/
   
3. Create a production environment file locally:
   cp .env .env.production
   
   Edit .env.production to update NEXTAUTH_URL:
   NEXTAUTH_URL=http://${PUBLIC_IP}
   
4. Copy the environment file to EC2:
   scp -i ${EC2_KEY_NAME}.pem .env.production ec2-user@${PUBLIC_IP}:~/

5. SSH into your instance:
   ssh -i ${EC2_KEY_NAME}.pem ec2-user@${PUBLIC_IP}

6. Run the deployment script on the EC2 instance:
   bash remote-deploy.sh

7. Access your application at:
   http://${PUBLIC_IP}

IMPORTANT NOTES:
- This setup uses only AWS Free Tier eligible resources
- Monitor your usage to avoid unexpected charges
- EC2 Free Tier includes 750 hours per month (about 1 t2.micro running 24/7)
- To stop the instance when not in use, run:
  aws ec2 stop-instances --instance-ids ${INSTANCE_ID}

EOF

echo -e "${GREEN}Deployment setup complete!${NC}"
echo -e "${YELLOW}See DEPLOYMENT_INSTRUCTIONS.txt for next steps${NC}" 