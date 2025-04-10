# TruVoice Application

This repository contains the TruVoice application, which is deployed on AWS EC2 t2.micro instances using K3s, Terraform, and GitHub Actions.

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

