# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automating the build, deployment, and infrastructure management of the TruVoice application.

## Available Workflows

1. **Terraform CI/CD** (`terraform.yml`): Handles infrastructure deployment with Terraform.
2. **Docker Build & Push** (`docker-build.yml`): Builds and pushes the Docker image to GitHub Container Registry.
3. **Build and Deploy** (`deploy.yml`): Combined workflow for building the image and deploying to K3s clusters.

## Required Secrets

The following secrets need to be configured in your GitHub repository:

### AWS Credentials
- `AWS_ACCESS_KEY_ID`: AWS access key with permissions to create resources
- `AWS_SECRET_ACCESS_KEY`: Corresponding AWS secret key

### SSH Keys
- `SSH_PRIVATE_KEY`: Private SSH key for connecting to EC2 instances
- `SSH_PUBLIC_KEY`: Public SSH key to be deployed to EC2 instances

## How to Use

### For Infrastructure Management

The Terraform workflow handles infrastructure changes. It will:
- Run automatically on pushes to the `main` branch that affect Terraform files
- Run on pull requests that modify Terraform files
- Can be manually triggered with different actions (plan, apply, destroy)

### For Application Deployment

The Docker workflow builds and pushes the container image when code changes are made.

### For Complete Deployment

The combined Build and Deploy workflow can be manually triggered to:
- Choose target environment (dev/staging/production)
- Choose to deploy infrastructure, application, or both
- Manage deployment across environments

## Adding New Environments

To add a new environment:
1. Trigger the "Build and Deploy" workflow
2. Select the new environment name
3. The workflow will create a new Terraform workspace for that environment

## Workflow Dependencies

```
┌──────────────┐
│ Docker Build │
└───────┬──────┘
        │
        ▼
┌──────────────┐     ┌──────────────┐
│   Terraform  │────▶│    Deploy    │
└──────────────┘     └──────────────┘
```

## Troubleshooting

- **Missing Secrets**: Ensure all required secrets are configured in Repository Settings -> Secrets
- **Infrastructure Issues**: Check Terraform logs in the workflow run
- **Deployment Failures**: Verify kubeconfig is correctly generated and kubectl commands succeed
- **Image Pull Issues**: Confirm GitHub Container Registry permissions and image tags 