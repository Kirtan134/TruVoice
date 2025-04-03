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
  default     = "ami-0261755bbcb8c4a84" # Ubuntu 22.04 LTS in us-east-1, update for other regions
}

variable "master_instance_type" {
  description = "Instance type for the K3s master node"
  type        = string
  default     = "t3.medium" # Minimum 2 CPU, 4GB RAM recommended for K3s master
}

variable "worker_instance_type" {
  description = "Instance type for the K3s worker nodes"
  type        = string
  default     = "t3.small" # Minimum 2 CPU, 2GB RAM for K3s workers
}

variable "worker_count" {
  description = "Number of K3s worker nodes"
  type        = number
  default     = 2
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