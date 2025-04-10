variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment (dev, staging, production)"
  type        = string
  default     = "dev"
}

variable "ubuntu_ami" {
  description = "Ubuntu 22.04 LTS AMI ID"
  type        = string
  default     = "ami-0e35ddab05955cf57" 
}

variable "master_instance_type" {
  description = "Instance type for the K3s master node"
  type        = string
  default     = "t2.micro" # Using t2.micro for cost optimization
}

variable "worker_instance_type" {
  description = "Instance type for the K3s worker nodes"
  type        = string
  default     = "t2.micro" # Using t2.micro for cost optimization
}

variable "worker_count" {
  description = "Number of K3s worker nodes"
  type        = number
  default     = 1 # Reduced to 1 worker for t2.micro
}

variable "public_key_path" {
  description = "Path to the public SSH key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to the private SSH key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository for Docker images"
  type        = string
  default     = "truvoice"
}

variable "tags" {
  description = "Default tags for all resources"
  type        = map(string)
  default = {
    Project     = "TruVoice"
    ManagedBy   = "Terraform"
  }
} 