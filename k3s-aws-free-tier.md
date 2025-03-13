# TruVoice Kubernetes Deployment on AWS Free Tier

This guide provides instructions for deploying TruVoice using **Kubernetes on AWS Free Tier** resources by using **k3s** (a lightweight Kubernetes distribution) on a t2.micro EC2 instance.

## Why K3s on EC2?

- **Free Tier Compatible**: Runs on t2.micro instances eligible for AWS Free Tier
- **Real Kubernetes**: K3s is a certified Kubernetes distribution
- **Lightweight**: Uses only ~512MB RAM, perfect for smaller instances
- **Full Feature Set**: Supports deployments, services, ingress and more

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
   - Allow Custom TCP (port 6443) from your IP (for Kubernetes API)
10. Review and Launch
11. Create or select an existing key pair for SSH access
12. Launch instance

### 2. Install k3s on EC2

Connect to your EC2 instance via SSH:

```bash
ssh -i your-key.pem ec2-user@your-instance-public-ip
```

Install k3s (single-node Kubernetes):

```bash
# Update system
sudo yum update -y

# Install k3s
curl -sfL https://get.k3s.io | sh -

# Wait for k3s to start
sleep 10

# Check that Kubernetes is running
sudo k3s kubectl get nodes

# Create .kube directory and config for the current user
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown ec2-user:ec2-user ~/.kube/config
sudo chmod 600 ~/.kube/config
export KUBECONFIG=~/.kube/config
echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc

# Verify kubectl works
kubectl get nodes
```

### 3. Install Docker for Building Images

Install Docker on the EC2 instance:

```bash
# Install Docker
sudo amazon-linux-extras install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Log out and log back in for group changes to take effect
exit
```

Reconnect and verify Docker installation:

```bash
ssh -i your-key.pem ec2-user@your-instance-public-ip
docker --version
```

### 4. Deploy the TruVoice Application

Clone your repository and build the Docker image:

```bash
# Clone the repository
git clone https://github.com/your-username/truvoice.git
cd truvoice

# Build the Docker image
docker build -t truvoice:latest .
```

Create Kubernetes manifest files for your application:

```bash
# Create a directory for Kubernetes manifests
mkdir -p k8s
```

Create a deployment manifest:

```bash
cat > k8s/deployment.yaml << 'EOF'
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
          value: http://your-ec2-public-ip
EOF
```

Create a service manifest:

```bash
cat > k8s/service.yaml << 'EOF'
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
```

Create a secret manifest template:

```bash
cat > k8s/secret-template.yaml << 'EOF'
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
```

Create your actual secrets file:

```bash
cp k8s/secret-template.yaml k8s/secrets.yaml
# Now edit this file with your actual values
nano k8s/secrets.yaml
```

Create an ingress for external access:

```bash
cat > k8s/ingress.yaml << 'EOF'
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
```

Apply the manifests to deploy your application:

```bash
# Apply the secrets first
kubectl apply -f k8s/secrets.yaml

# Apply the other manifests
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Check if pods are running
kubectl get pods

# Wait for the deployment to be ready
kubectl rollout status deployment/truvoice-app
```

### 5. Accessing Your Application

Find the port assigned to your service:

```bash
kubectl get svc truvoice-service
```

This will show the NodePort assigned (e.g. 31234). You can access your application at:

```
http://your-ec2-public-ip:31234
```

Alternatively, to make it accessible via port 80, you can set up port forwarding on the EC2 instance:

```bash
# Find the NodePort assigned
NODE_PORT=$(kubectl get svc truvoice-service -o jsonpath='{.spec.ports[0].nodePort}')

# Set up port forwarding (needs to be reapplied after instance restart)
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port $NODE_PORT
```

### 6. Setting Up Auto-Deployment

Create a deployment script for easier updates:

```bash
cat > deploy.sh << 'EOF'
#!/bin/bash
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

echo "Deployment complete!"
echo "Your application is available at: http://$INSTANCE_IP:$NODE_PORT"
echo "If you've set up port forwarding, it's also available at: http://$INSTANCE_IP"
EOF

chmod +x deploy.sh
```

## Monitoring and Maintenance

### View Kubernetes Resources

```bash
# List all pods
kubectl get pods

# Get pod details
kubectl describe pod [pod-name]

# View pod logs
kubectl logs [pod-name]

# List all services
kubectl get services

# List all deployments
kubectl get deployments
```

### Update the Application

To update your application:

1. Pull latest code changes
2. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

### Backup Kubernetes Resources

```bash
kubectl get all --all-namespaces -o yaml > k8s-backup.yaml
```

## Staying Within Free Tier Limits

1. **Monitor EC2 usage**: Ensure you stay within 750 hours per month
2. **Watch EC2 storage**: Keep under 30GB of EBS storage
3. **Set up billing alerts**: Create CloudWatch alarms to be notified if you're approaching free tier limits

## Troubleshooting

1. **Pods stuck in pending state**: Check resources with `kubectl describe pod [pod-name]`
2. **Image pull errors**: Since we're using local images with `imagePullPolicy: Never`, ensure images are built on the instance
3. **Application not accessible**: Check service NodePort and security group settings
4. **k3s issues**: Check logs with `sudo journalctl -u k3s`

## Advanced: Setting up a CI/CD Pipeline

For a more sophisticated setup, you can create a GitHub Actions workflow to automate deployment:

1. Create a new file `.github/workflows/deploy.yml` in your repository
2. Add SSH credentials as GitHub secrets
3. Configure automatic deployment on push to main branch

This workflow can SSH into your EC2 instance, pull the latest code, and run the deployment script.

---

This deployment gives you a real Kubernetes environment to work with while staying within AWS Free Tier limits. 