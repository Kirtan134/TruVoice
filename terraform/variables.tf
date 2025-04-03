variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "ap-south-1"
}

variable "ubuntu_ami" {
  description = "Ubuntu 24.04 LTS AMI ID"
  type        = string
  default     = "ami-0e35ddab05955cf57"
}

variable "master_instance_type" {
  description = "Instance type for the K3s master node"
  type        = string
  default     = "t2.micro"
}

variable "worker_instance_type" {
  description = "Instance type for the K3s worker nodes"
  type        = string
  default     = "t2.micro"
}

variable "worker_count" {
  description = "Number of K3s worker nodes"
  type        = number
  default     = 1
}

variable "public_key_path" {
  description = "Path to the public SSH key"
  type        = string
  default     = "~/.ssh/aws_key.pub"
}

variable "private_key_path" {
  description = "Path to the private SSH key"
  type        = string
  default     = "~/.ssh/aws_key"
} 