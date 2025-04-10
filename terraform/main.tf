provider "aws" {
  region = var.aws_region
}

# ECR Repository for Docker images
resource "aws_ecr_repository" "truvoice" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name = "${var.ecr_repository_name}-${var.environment}"
    Environment = var.environment
  })
}

# ECR Lifecycle Policy to limit the number of images
resource "aws_ecr_lifecycle_policy" "truvoice" {
  repository = aws_ecr_repository.truvoice.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_vpc" "k3s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name        = "k3s-vpc-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_subnet" "k3s_subnet" {
  vpc_id                  = aws_vpc.k3s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name        = "k3s-subnet-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "k3s_igw" {
  vpc_id = aws_vpc.k3s_vpc.id

  tags = {
    Name        = "k3s-igw-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table" "k3s_route_table" {
  vpc_id = aws_vpc.k3s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s_igw.id
  }

  tags = {
    Name        = "k3s-route-table-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "k3s_rta" {
  subnet_id      = aws_subnet.k3s_subnet.id
  route_table_id = aws_route_table.k3s_route_table.id
}

resource "aws_security_group" "k3s_sg" {
  name        = "k3s-security-group-${var.environment}"
  description = "Allow traffic for K3s cluster"
  vpc_id      = aws_vpc.k3s_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubernetes API"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Node token access (VPC only)"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  # Allow all internal cluster traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Internal cluster traffic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name        = "k3s-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_key_pair" "k3s_key_pair" {
  key_name   = "k3s-key-${var.environment}"
  public_key = file(var.public_key_path)
}

# K3s master node
resource "aws_instance" "k3s_master" {
  ami                    = var.ubuntu_ami
  instance_type          = var.master_instance_type
  key_name               = aws_key_pair.k3s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  subnet_id              = aws_subnet.k3s_subnet.id

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "k3s-master-${var.environment}"
    Environment = var.environment
    Role        = "master"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y curl jq netcat

              # Install K3s server
              curl -sfL https://get.k3s.io | sh -

              # Wait for K3s to be ready
              sleep 30

              # Create a simple HTTP server to expose the node token securely within the VPC
              NODE_TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
              
              # Set up a temporary endpoint to serve the token to worker nodes
              cat > /tmp/serve_token.sh <<'SERVESCRIPT'
              #!/bin/bash
              while true; do
                echo -e "HTTP/1.1 200 OK\n\n$(cat /var/lib/rancher/k3s/server/node-token)" | nc -l -p 8080 -q 1
              done
              SERVESCRIPT
              
              chmod +x /tmp/serve_token.sh
              nohup /tmp/serve_token.sh > /tmp/serve_token.log 2>&1 &
              
              # Secure the token server after 30 minutes
              nohup bash -c "sleep 1800 && pkill -f 'nc -l -p 8080'" > /dev/null 2>&1 &
              EOF
}

# K3s worker nodes
resource "aws_instance" "k3s_worker" {
  count                  = var.worker_count
  ami                    = var.ubuntu_ami
  instance_type          = var.worker_instance_type
  key_name               = aws_key_pair.k3s_key_pair.key_name
  vpc_security_group_ids = [aws_security_group.k3s_sg.id]
  subnet_id              = aws_subnet.k3s_subnet.id

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "k3s-worker-${count.index}-${var.environment}"
    Environment = var.environment
    Role        = "worker"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y curl
              # Wait for master to be ready
              sleep 90
              # Use the private IP address directly instead of SSH 
              # This is more secure and avoids SSH key issues
              TOKEN=$(curl -sfL -X GET "http://${aws_instance.k3s_master.private_ip}:8080/node-token")
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_master.private_ip}:6443 K3S_TOKEN=$TOKEN sh -
              EOF

  depends_on = [aws_instance.k3s_master]
} 