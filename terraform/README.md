# TruVoice K3s Terraform Configuration

This directory contains Terraform configurations to deploy a K3s Kubernetes cluster on Ubuntu EC2 instances in AWS, along with the TruVoice application.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed (v1.0.0+)
- AWS account with appropriate permissions
- AWS CLI configured with access credentials
- SSH key pair for accessing EC2 instances

## Configuration

Before applying the Terraform configuration, you may want to customize the following variables in `variables.tf`:

- `aws_region`: AWS region to deploy the infrastructure (default: `us-east-1`)
- `ubuntu_ami`: Ubuntu 22.04 LTS AMI ID (update for your chosen region)
- `master_instance_type`: Instance type for the K3s master node 
- `worker_instance_type`: Instance type for the K3s worker nodes
- `worker_count`: Number of K3s worker nodes (default: `2`)
- `public_key_path`: Path to your public SSH key (default: `~/.ssh/id_rsa.pub`)
- `private_key_path`: Path to your private SSH key (default: `~/.ssh/id_rsa`)

## Deployment Steps

1. Initialize the Terraform working directory:
   ```
   terraform init
   ```

2. Review the planned changes:
   ```
   terraform plan
   ```

3. Apply the configuration:
   ```
   terraform apply
   ```

4. After successful deployment, Terraform will output:
   - Public IP of the K3s master node
   - Public IPs of the K3s worker nodes
   - Command to copy K3s kubeconfig from the master node

## Accessing the Cluster

After the deployment is complete, you can access your K3s cluster using kubectl:

1. Run the command provided in the Terraform output to get the kubeconfig file:
   ```
   ssh -i ~/.ssh/id_rsa ubuntu@<master-ip> sudo cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml && sed -i 's/127.0.0.1/<master-ip>/g' kubeconfig.yaml
   ```

2. Set the KUBECONFIG environment variable:
   ```
   export KUBECONFIG=$(pwd)/kubeconfig.yaml
   ```

3. Verify connectivity:
   ```
   kubectl get nodes
   ```

## Accessing the TruVoice Application

The TruVoice application will be deployed automatically to the K3s cluster. You can access it at:

```
http://<master-ip>
```

## Clean Up

To destroy the infrastructure when no longer needed:

```
terraform destroy
```

## Helper Script

The `scripts/configure-k3s.sh` script can be used to retrieve the K3s token and kubeconfig after the nodes are provisioned. Run it with:

```
./scripts/configure-k3s.sh <master-ip> <private-key-path>
``` 