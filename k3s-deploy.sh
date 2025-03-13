#!/bin/bash
# TruVoice K3s Deployment Script - AWS Free Tier Compatible
# This script helps deploy the TruVoice application to a single EC2 instance with k3s

set -e  # Exit on error

# Color codes for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment process for TruVoice to AWS EC2 with K3s (Free Tier)...${NC}"

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

echo -e "${GREEN}   AWS account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}   AWS region: ${AWS_REGION}${NC}"

# 2. Create EC2 key pair if needed
EC2_KEY_NAME="truvoice-k3s-key"
echo -e "${YELLOW}2. Checking for EC2 key pair...${NC}"
if aws ec2 describe-key-pairs --key-names ${EC2_KEY_NAME} 2>&1 | grep -q "InvalidKeyPair.NotFound"; then
    echo -e "${YELLOW}   Creating new key pair: ${EC2_KEY_NAME}${NC}"
    aws ec2 create-key-pair --key-name ${EC2_KEY_NAME} --query 'KeyMaterial' --output text > ${EC2_KEY_NAME}.pem
    chmod 400 ${EC2_KEY_NAME}.pem
    echo -e "${GREEN}   Key pair created and saved to ${EC2_KEY_NAME}.pem${NC}"
    echo -e "${YELLOW}   IMPORTANT: Keep this file safe. It will be needed to SSH into your instance.${NC}"
else
    echo -e "${GREEN}   Key pair ${EC2_KEY_NAME} already exists${NC}"
fi

# 3. Create security group
SECURITY_GROUP_NAME="truvoice-k3s-sg"
echo -e "${YELLOW}3. Setting up security group...${NC}"
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=${SECURITY_GROUP_NAME} --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || echo "")

if [ "$SECURITY_GROUP_ID" = "None" ] || [ -z "$SECURITY_GROUP_ID" ]; then
    echo -e "${YELLOW}   Creating new security group: ${SECURITY_GROUP_NAME}${NC}"
    SECURITY_GROUP_ID=$(aws ec2 create-security-group --group-name ${SECURITY_GROUP_NAME} --description "Security group for TruVoice application with K3s" --query 'GroupId' --output text)
    
    # Allow SSH from current IP
    MY_IP=$(curl -s https://checkip.amazonaws.com)
    aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 22 --cidr ${MY_IP}/32
    
    # Allow HTTP and HTTPS from anywhere
    aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 80 --cidr 0.0.0.0/0
    aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 443 --cidr 0.0.0.0/0
    
    # Allow Kubernetes API from current IP
    aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 6443 --cidr ${MY_IP}/32
    
    # Allow NodePort range
    aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 30000-32767 --cidr 0.0.0.0/0
    
    echo -e "${GREEN}   Security group created with ID: ${SECURITY_GROUP_ID}${NC}"
else
    echo -e "${GREEN}   Using existing security group: ${SECURITY_GROUP_ID}${NC}"
fi

# 4. Launch EC2 instance
echo -e "${YELLOW}4. Launching EC2 instance (t2.micro - Free Tier eligible)...${NC}"

# Get latest Amazon Linux 2 AMI ID
AMI_ID=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*-x86_64-gp2" "Name=state,Values=available" --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)

echo -e "${YELLOW}   Using Amazon Linux 2 AMI: ${AMI_ID}${NC}"

# Create user data script for instance initialization
cat > user-data.sh << 'EOF'
#!/bin/bash
# Initialize instance
yum update -y

# Install Docker
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Wait for k3s to initialize
sleep 10

# Setup kubectl for ec2-user
mkdir -p /home/ec2-user/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube
echo 'export KUBECONFIG=/home/ec2-user/.kube/config' >> /home/ec2-user/.bashrc
chmod 600 /home/ec2-user/.kube/config

# Create a welcome message
echo "TruVoice K3s server setup complete. Run deployment script to complete installation." > /home/ec2-user/welcome.txt
chown ec2-user:ec2-user /home/ec2-user/welcome.txt
EOF

# Launch the instance
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ${AMI_ID} \
    --instance-type t2.micro \
    --key-name ${EC2_KEY_NAME} \
    --security-group-ids ${SECURITY_GROUP_ID} \
    --user-data file://user-data.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=TruVoice-K3s-Server}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "${GREEN}   EC2 instance launched with ID: ${INSTANCE_ID}${NC}"

# 5. Wait for instance to be running
echo -e "${YELLOW}5. Waiting for instance to be running...${NC}"
aws ec2 wait instance-running --instance-ids ${INSTANCE_ID}

# Get public IP address
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids ${INSTANCE_ID} --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo -e "${GREEN}   Instance is running with public IP: ${PUBLIC_IP}${NC}"

# 6. Prepare Kubernetes configuration files
echo -e "${YELLOW}6. Preparing Kubernetes configuration files...${NC}"

mkdir -p k8s-deploy-files

# Create deployment.yaml
cat > k8s-deploy-files/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: truvoice-app
  labels:
    app: truvoice
spec:
  replicas: 1
  selector:
    matchLabels:
      app: truvoice
  template:
    metadata:
      labels:
        app: truvoice
    spec:
      containers:
      - name: truvoice
        image: truvoice:latest
        imagePullPolicy: Never
        ports:
        - containerPort: 3000
        resources:
          limits:
            cpu: "0.5"
            memory: "512Mi"
          requests:
            cpu: "0.25"
            memory: "256Mi"
        env:
        - name: MONGODB_URI
          valueFrom:
            secretKeyRef:
              name: truvoice-secrets
              key: mongodb-uri
        - name: NEXTAUTH_SECRET
          valueFrom:
            secretKeyRef:
              name: truvoice-secrets
              key: nextauth-secret
        - name: GEMINI_API_KEY
          valueFrom:
            secretKeyRef:
              name: truvoice-secrets
              key: gemini-api-key
        - name: CLIENT_ID
          valueFrom:
            secretKeyRef:
              name: truvoice-secrets
              key: client-id
        - name: CLIENT_SECRET
          valueFrom:
            secretKeyRef:
              name: truvoice-secrets
              key: client-secret
        - name: REDIRECT_URI
          valueFrom:
            secretKeyRef:
              name: truvoice-secrets
              key: redirect-uri
        - name: REFRESH_TOKEN
          valueFrom:
            secretKeyRef:
              name: truvoice-secrets
              key: refresh-token
        - name: EMAIL
          valueFrom:
            secretKeyRef:
              name: truvoice-secrets
              key: email
        - name: NEXTAUTH_URL
          value: http://${PUBLIC_IP}
EOF

# Create service.yaml
cat > k8s-deploy-files/service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: truvoice-service
spec:
  selector:
    app: truvoice
  ports:
  - port: 80
    targetPort: 3000
  type: NodePort
EOF

# Create ingress.yaml
cat > k8s-deploy-files/ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: truvoice-ingress
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: truvoice-service
            port:
              number: 80
EOF

# Create secret-template.yaml
cat > k8s-deploy-files/secret-template.yaml << EOF
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
EOF

echo -e "${GREEN}   Kubernetes configuration files created in k8s-deploy-files/directory${NC}"

# 7. Create deployment script for remote instance
echo -e "${YELLOW}7. Creating deployment script for remote instance...${NC}"

cat > k8s-deploy-files/deploy.sh << 'EOF'
#!/bin/bash
# K3s deployment script for TruVoice
set -e

# Variables
APP_NAME="truvoice"

# Build new Docker image
echo "Building Docker image..."
docker build -t $APP_NAME:latest .

# Apply Kubernetes configurations
echo "Applying Kubernetes configurations..."
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Restart deployment to pick up new image
echo "Restarting deployment..."
kubectl rollout restart deployment/$APP_NAME-app

# Wait for deployment to complete
echo "Waiting for deployment to complete..."
kubectl rollout status deployment/$APP_NAME-app

# Get service URL
NODE_PORT=$(kubectl get svc $APP_NAME-service -o jsonpath='{.spec.ports[0].nodePort}')
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Set up port forwarding from 80 to NodePort (optional)
echo "Setting up port forwarding from port 80 to NodePort $NODE_PORT..."
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $NODE_PORT
sudo iptables -t nat -A OUTPUT -p tcp -d localhost --dport 80 -j REDIRECT --to-port $NODE_PORT

echo "Deployment complete!"
echo "Your application is available at: http://$INSTANCE_IP:$NODE_PORT"
echo "After port forwarding, it's also available at: http://$INSTANCE_IP"
EOF

chmod +x k8s-deploy-files/deploy.sh

# 8. Create deployment instructions
echo -e "${YELLOW}8. Creating deployment instructions...${NC}"

cat > KUBERNETES_DEPLOYMENT_INSTRUCTIONS.txt << EOF
========== TRUVOICE KUBERNETES (K3S) DEPLOYMENT INSTRUCTIONS ==========

Your EC2 instance has been created with IP: ${PUBLIC_IP}

NEXT STEPS:

1. Wait 3-5 minutes for the instance to complete initialization and install k3s

2. Create k8s directory on your local machine for secrets:
   mkdir -p k8s-deploy-files/k8s

3. Create a secrets.yaml file with your actual values:
   cp k8s-deploy-files/secret-template.yaml k8s-deploy-files/k8s/secrets.yaml
   nano k8s-deploy-files/k8s/secrets.yaml  # Edit with your actual values
   
   NOTE: Make sure to update the mongodb-uri and other values with your actual credentials

4. Copy the other Kubernetes manifests to the k8s directory:
   cp k8s-deploy-files/deployment.yaml k8s-deploy-files/k8s/
   cp k8s-deploy-files/service.yaml k8s-deploy-files/k8s/
   cp k8s-deploy-files/ingress.yaml k8s-deploy-files/k8s/

5. Copy the deploy script, Kubernetes manifests, and your application code to the EC2 instance:
   scp -i ${EC2_KEY_NAME}.pem -r k8s-deploy-files/k8s ec2-user@${PUBLIC_IP}:~/
   scp -i ${EC2_KEY_NAME}.pem k8s-deploy-files/deploy.sh ec2-user@${PUBLIC_IP}:~/
   scp -i ${EC2_KEY_NAME}.pem -r ./* ec2-user@${PUBLIC_IP}:~/truvoice/
   
   NOTE: This assumes your TruVoice code is in the current directory

6. SSH into your instance:
   ssh -i ${EC2_KEY_NAME}.pem ec2-user@${PUBLIC_IP}

7. Deploy your application:
   cd ~/truvoice
   chmod +x ~/deploy.sh
   ~/deploy.sh

8. Check your deployment:
   kubectl get pods
   kubectl get services

9. Access your application at:
   http://${PUBLIC_IP}

WORKING WITH KUBERNETES (CHEAT SHEET):

- Get resources:
  kubectl get pods
  kubectl get deployments
  kubectl get services
  kubectl get ingress

- Get details:
  kubectl describe pod <pod-name>
  kubectl logs <pod-name>

- Update the application:
  cd ~/truvoice
  git pull  # (if connected to git)
  ~/deploy.sh

IMPORTANT NOTES:
- This setup uses only AWS Free Tier eligible resources
- Monitor your usage to avoid unexpected charges
- EC2 Free Tier includes 750 hours per month (about 1 t2.micro running 24/7)
- To stop the instance when not in use, run:
  aws ec2 stop-instances --instance-ids ${INSTANCE_ID}

EOF

echo -e "${GREEN}Deployment setup complete!${NC}"
echo -e "${YELLOW}See KUBERNETES_DEPLOYMENT_INSTRUCTIONS.txt for next steps${NC}"
echo -e "${YELLOW}Your Kubernetes configuration files are in the k8s-deploy-files directory${NC}" 