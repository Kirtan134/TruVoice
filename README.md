# TruVoice

### The World of Anonymous Feedback

TruVoice - Where your identity remains a secret. Now with the power of AI.

### Deployment Video

🎥 [Click here to watch the video](https://drive.google.com/file/d/14Rq4M2Jejxe0DEhsQElM9__MlUWLtlg_/view?usp=sharing)


## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Usage](#usage)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Contributing](#contributing)
- [License](#license)

## Introduction

TruVoice is an innovative platform designed to allow users to give and receive anonymous feedback. With the integration of AI, users can generate thoughtful and constructive feedback easily. Whether authenticated or not, users can provide feedback securely and anonymously.

## Features

- **Anonymous Feedback:** Receive feedback from others while keeping your identity secret.
- **Email Authentication:** Authenticate via email using OTP for secure feedback receipt.
- **AI-Generated Feedback:** Use Gemini AI to generate feedback messages.
- **Cross-Platform:** Fully responsive design for both desktop and mobile devices.
- **Monitoring:** Comprehensive monitoring with Prometheus and Grafana.

## Tech Stack

TruVoice is built using the following technologies:

- **Frontend:** Next.js, ShadCN
- **Backend:** Next.js API routes
- **Database:** MongoDB
- **Authentication:** Next-Auth, Auth.js, JWT tokens
- **Validation:** Zod
- **Email Services:** Nodemailer, Gmail API
- **AI Integration:** Gemini AI
- **Deployment:** Docker, Kubernetes (K3s)
- **CI/CD:** GitHub Actions
- **Infrastructure:** AWS (EC2, ECR)
- **Infrastructure as Code:** Terraform
- **Monitoring:** Prometheus, Grafana

## Installation

To get a local copy up and running, follow these simple steps:

1. Clone the repo
   ```sh
   git clone https://github.com/Kirtan134/TruVoice.git
   ```
2. Install NPM packages
   ```sh
   npm install
   ```
3. Set up environment variables
   - Create a `.env` file in the root directory
   - Add your MONGODB_URI, NEXTAUTH_SECRET, GEMINI_API_KEY, CLIENT_ID, CLIENT_SECRET, REDIRECT_URI, REFRESH_TOKEN and other necessary credentials

4. Run the development server
   ```sh
   npm run dev
   ```

## Usage

1. **Authentication:**
   - Sign up with your email.
   - Verify your email using the OTP sent to your inbox.

2. **Giving Feedback:**
   - Choose to authenticate or give feedback anonymously.
   - Use Gemini AI to generate feedback messages if needed.
   - Submit your feedback.

3. **Receiving Feedback:**
   - Receive feedback anonymously.
   - Manage your feedback through the user dashboard.

## Deployment

TruVoice can be deployed using Docker or Kubernetes. Below are instructions for both methods.

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

The application is deployed on a lightweight Kubernetes cluster (K3s) running on AWS EC2 t2.micro instances. The infrastructure is managed using Terraform, and the CI/CD pipeline is implemented using GitHub Actions.

#### Prerequisites

- AWS Account with appropriate permissions
- Terraform installed locally (for manual deployment)
- GitHub account with repository access
- SSH key pair for EC2 instance access
- kubectl configured to access your Kubernetes cluster

#### Manual Deployment with Terraform

1. Initialize Terraform:
   ```bash
   cd terraform
   terraform init
   ```

2. Create a terraform.tfvars file with your configuration:
   ```hcl
   aws_region = "ap-south-1"
   environment = "dev"
   public_key_path = "~/.ssh/id_rsa.pub"
   private_key_path = "~/.ssh/id_rsa"
   ```

3. Apply the Terraform configuration:
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

4. Get the kubeconfig:
   ```bash
   terraform output kubectl_config_command
   ```

#### Deploying the Application

1. Apply the Kubernetes manifests:
   ```bash
   kubectl apply -f k8s/
   ```

2. Access the application:
   ```bash
   kubectl port-forward svc/truvoice-service 3000:3000
   ```

#### Automated Deployment with GitHub Actions

1. Fork the repository to your GitHub account.

2. Set up the following GitHub Secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `AWS_REGION`: The AWS region to deploy to (e.g., ap-south-1)

3. Push changes to the main branch to trigger the CI/CD pipeline.

## Monitoring

TruVoice includes comprehensive monitoring with Prometheus and Grafana.

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
- Password: `admin123` (change this in production!)

### Metrics Endpoint

The application exposes metrics at `/api/metrics` for Prometheus to scrape. These metrics include:

- HTTP request duration
- HTTP request count
- Voice recording duration
- Authentication attempts

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

## Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contributors

- Kirtan Parikh (@Kirtan134)

