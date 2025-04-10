# TruVoice - Voice Authentication System

A secure voice authentication system built with Next.js, featuring real-time voice recording, authentication, and user management.

## Features

- **Voice Authentication**: Secure voice-based user authentication
- **Real-time Recording**: Browser-based voice recording with visual feedback
- **User Management**: Secure user registration and profile management
- **Modern UI**: Clean, responsive interface built with Tailwind CSS
- **Monitoring**: Prometheus and Grafana integration for metrics and monitoring

## Tech Stack

- **Frontend**: Next.js, React, Tailwind CSS
- **Backend**: Next.js API Routes
- **Authentication**: Voice-based authentication
- **Database**: MongoDB (via MongoDB Atlas)
- **Deployment**: Docker, Kubernetes
- **CI/CD**: GitHub Actions
- **Infrastructure**: AWS (EC2, ECR)
- **Infrastructure as Code**: Terraform
- **Monitoring**: Prometheus, Grafana

## Prerequisites

- Node.js 18.x or higher
- Docker
- kubectl
- AWS CLI
- Terraform

## Getting Started

### Local Development

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/truvoice.git
   cd truvoice
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env.local` file with the following variables:
   ```
   MONGODB_URI=your_mongodb_uri
   JWT_SECRET=your_jwt_secret
   ```

4. Run the development server:
   ```bash
   npm run dev
   ```

5. Open [http://localhost:3000](http://localhost:3000) in your browser.

### Docker Deployment

1. Build the Docker image:
   ```bash
   docker build -t truvoice:latest .
   ```

2. Run the container:
   ```bash
   docker run -p 3000:3000 --env-file .env.local truvoice:latest
   ```

### Kubernetes Deployment

1. Apply the Kubernetes manifests:
   ```bash
   kubectl apply -f k8s/
   ```

2. Access the application:
   ```bash
   kubectl port-forward svc/truvoice-service 3000:3000
   ```

## Monitoring Setup

The application includes Prometheus and Grafana for monitoring:

### Prometheus

Prometheus is deployed in the `monitoring` namespace and configured to scrape metrics from:

- Node Exporter (system metrics)
- Application metrics endpoint (`/api/metrics`)

Access Prometheus at: `http://<your-server-ip>:30090`

### Grafana

Grafana is deployed in the `monitoring` namespace and configured to use Prometheus as a data source.

Access Grafana at: `http://<your-server-ip>:30300`

Default credentials:
- Username: `admin`
- Password: `admin`

### Metrics Endpoint

The application exposes metrics at `/api/metrics` for Prometheus to scrape. These metrics include:

- HTTP request duration
- HTTP request count
- Voice recording duration
- Authentication attempts

## Infrastructure Setup

### AWS Setup

1. Configure AWS credentials:
   ```bash
   aws configure
   ```

2. Apply Terraform configuration:
   ```bash
   cd terraform
   terraform init
   terraform plan
   terraform apply
   ```

### CI/CD Pipeline

The project includes a GitHub Actions workflow for CI/CD:

1. Builds and tests the application
2. Builds a Docker image
3. Pushes the image to Amazon ECR
4. Deploys to Kubernetes

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Next.js team for the amazing framework
- Tailwind CSS for the utility-first CSS framework
- Prometheus and Grafana for the monitoring tools

## Architecture

The application is deployed on a lightweight Kubernetes cluster (K3s) running on AWS EC2 t2.micro instances. The infrastructure is managed using Terraform, and the CI/CD pipeline is implemented using GitHub Actions.

### Components

- **K3s Cluster**: A lightweight Kubernetes distribution running on EC2 t2.micro instances
- **Prometheus & Grafana**: For monitoring and observability
- **ECR Repository**: For storing Docker images
- **GitHub Actions**: For CI/CD pipeline

## Prerequisites

- AWS Account with appropriate permissions
- Terraform installed locally (for manual deployment)
- GitHub account with repository access
- SSH key pair for EC2 instance access

## Setup Instructions

### 1. Manual Deployment with Terraform

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/truvoice.git
   cd truvoice
   ```

2. Initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

3. Create a terraform.tfvars file with your configuration:
   ```hcl
   aws_region = "ap-south-1"
   environment = "dev"
   public_key_path = "~/.ssh/id_rsa.pub"
   private_key_path = "~/.ssh/id_rsa"
   ```

4. Apply the Terraform configuration:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

5. Get the kubeconfig:
   ```bash
   terraform output kubectl_config_command
   ```

### 2. Automated Deployment with GitHub Actions

1. Fork the repository to your GitHub account.

2. Set up the following GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `AWS_REGION`: The AWS region to deploy to (e.g., ap-south-1)

3. Push changes to the main branch to trigger the CI/CD pipeline.

## Monitoring

The application is monitored using Prometheus and Grafana:

- **Prometheus**: Available at `http://<master-ip>:9090`
- **Grafana**: Available at `http://<master-ip>:3000`

Default Grafana credentials:
- Username: admin
- Password: admin123 (change this in production!)

## Cost Optimization

This setup is optimized for cost by using t2.micro instances. However, these instances have limited resources, so monitor your application's performance and consider upgrading if needed.

## Troubleshooting

### Common Issues

1. **K3s cluster not starting**:
   - Check the EC2 instance logs
   - Verify security group settings
   - Ensure the instance has enough resources

2. **GitHub Actions deployment failing**:
   - Check the GitHub Actions logs
   - Verify AWS credentials
   - Ensure the ECR repository exists

3. **Monitoring not working**:
   - Check if Prometheus and Grafana pods are running
   - Verify network connectivity between pods
   - Check Prometheus targets in the UI

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributors

- Kirtan Parikh (@Kirtan134)
---

