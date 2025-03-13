# AWS Free Tier Deployment Guide for TruVoice

This guide focuses on deploying the TruVoice application using **only AWS Free Tier** eligible resources.

## AWS Free Tier Resources Used

- **EC2**: 1 t2.micro instance (750 hours per month free)
- **ECR**: 500MB of storage for Docker images (free for 12 months)
- **Route 53**: For DNS management (not completely free, but minimal cost if needed)

## Deployment Steps

### 1. Launch an EC2 Instance

1. Log in to AWS Management Console
2. Navigate to EC2 Dashboard
3. Click "Launch Instance"
4. Select an Amazon Linux 2 AMI
5. Choose t2.micro instance type (Free Tier eligible)
6. Configure instance details (use defaults)
7. Add storage (use defaults, stay within 30GB for Free Tier)
8. Add tags (optional)
9. Configure security group:
   - Allow SSH (port 22) from your IP
   - Allow HTTP (port 80) from anywhere
   - Allow HTTPS (port 443) from anywhere
10. Review and Launch
11. Create or select an existing key pair for SSH access
12. Launch instance

### 2. Install Docker on EC2

Connect to your EC2 instance via SSH:

```bash
ssh -i your-key.pem ec2-user@your-instance-public-ip
```

Install Docker:

```bash
# Update system
sudo yum update -y

# Install Docker
sudo amazon-linux-extras install docker -y
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Log out and log back in for group changes to take effect
exit
```

Reconnect via SSH and verify Docker installation:

```bash
ssh -i your-key.pem ec2-user@your-instance-public-ip
docker --version
```

### 3. Configure AWS CLI and ECR

Install AWS CLI and configure it:

```bash
sudo yum install -y aws-cli
aws configure
# Enter your AWS credentials
```

Create ECR repository:

```bash
aws ecr create-repository --repository-name truvoice
```

### 4. Clone and Configure Your Application

Clone your repository:

```bash
git clone https://github.com/your-username/truvoice.git
cd truvoice
```

Create a `.env.production` file with your production environment variables:

```bash
# Example command - replace with your actual values
cat > .env.production << EOF
NEXTAUTH_SECRET=your-secret
MONGODB_URI=your-mongodb-uri
GEMINI_API_KEY=your-api-key
CLIENT_ID=your-client-id
CLIENT_SECRET=your-client-secret
REDIRECT_URI=your-redirect-uri
REFRESH_TOKEN=your-refresh-token
EMAIL=your-email
NEXTAUTH_URL=http://your-ec2-public-ip
EOF
```

### 5. Build and Deploy with Docker

Log in to ECR:

```bash
aws ecr get-login-password | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com
```

Build and push your Docker image:

```bash
# Build the Docker image
docker build -t truvoice:latest .

# Tag the image for ECR
docker tag truvoice:latest $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/truvoice:latest

# Push to ECR
docker push $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/truvoice:latest
```

Pull and run the container:

```bash
# Pull from ECR (optional if building locally)
docker pull $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/truvoice:latest

# Run the container
docker run -d --name truvoice -p 80:3000 \
  --restart unless-stopped \
  --env-file .env.production \
  $(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.$(aws configure get region).amazonaws.com/truvoice:latest
```

### 6. Set Up a Simple Deployment Script

Create a deployment script for easier updates:

```bash
cat > deploy.sh << 'EOF'
#!/bin/bash
set -e

# Variables
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
REPO_NAME="truvoice"
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest"

# Log in to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Build and push
echo "Building Docker image..."
docker build -t ${REPO_NAME}:latest .
docker tag ${REPO_NAME}:latest ${IMAGE_URI}
docker push ${IMAGE_URI}

# Stop and remove existing container
echo "Stopping existing container..."
docker stop truvoice || true
docker rm truvoice || true

# Run new container
echo "Starting new container..."
docker run -d --name truvoice -p 80:3000 \
  --restart unless-stopped \
  --env-file .env.production \
  ${IMAGE_URI}

echo "Deployment complete!"
EOF

chmod +x deploy.sh
```

### 7. Access Your Application

Your application should now be accessible at:

```
http://your-ec2-public-ip
```

For a custom domain name, you can use Route 53 (minimal cost) or a free DNS service like Cloudflare.

## Staying Within Free Tier Limits

1. **Monitor EC2 usage**: Ensure you stay within 750 hours per month (one instance running 24/7 for a month is about 720 hours)
2. **Watch ECR storage**: Stay under 500MB for Docker images
3. **EC2 storage**: Keep under 30GB of EBS storage

## Additional Free Tier Cost-Saving Tips

1. **Stop the instance when not in use**: If you don't need 24/7 availability, stop the instance to save free tier hours
2. **Set up billing alerts**: Create CloudWatch alarms to be notified if you're approaching free tier limits
3. **Clean up old Docker images**: Regularly remove unused images to stay within ECR free storage

## Monitoring and Maintenance

1. **View logs**:
   ```bash
   docker logs truvoice
   ```

2. **Enter the container**:
   ```bash
   docker exec -it truvoice /bin/sh
   ```

3. **Update the application**:
   ```bash
   ./deploy.sh
   ```

4. **Backup your data**: Regularly back up MongoDB data if it contains important information

## Troubleshooting

1. **Container won't start**: Check logs with `docker logs truvoice`
2. **Application not accessible**: Verify security group settings
3. **Database connection issues**: Ensure MongoDB URI is correctly set 