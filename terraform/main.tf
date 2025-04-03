provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "k3s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "k3s-vpc"
  }
}

resource "aws_subnet" "k3s_subnet" {
  vpc_id                  = aws_vpc.k3s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "k3s-subnet"
  }
}

resource "aws_internet_gateway" "k3s_igw" {
  vpc_id = aws_vpc.k3s_vpc.id

  tags = {
    Name = "k3s-igw"
  }
}

resource "aws_route_table" "k3s_route_table" {
  vpc_id = aws_vpc.k3s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s_igw.id
  }

  tags = {
    Name = "k3s-route-table"
  }
}

resource "aws_route_table_association" "k3s_rta" {
  subnet_id      = aws_subnet.k3s_subnet.id
  route_table_id = aws_route_table.k3s_route_table.id
}

resource "aws_security_group" "k3s_sg" {
  name        = "k3s-security-group"
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
    Name = "k3s-sg"
  }
}

resource "aws_key_pair" "k3s_key_pair" {
  key_name   = "k3s-key"
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
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name = "k3s-master"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y curl
              curl -sfL https://get.k3s.io | sh -
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
    volume_size = 10
    volume_type = "gp3"
  }

  tags = {
    Name = "k3s-worker-${count.index}"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y curl
              K3S_TOKEN=$(ssh -i /path/to/private_key -o StrictHostKeyChecking=no ubuntu@${aws_instance.k3s_master.private_ip} sudo cat /var/lib/rancher/k3s/server/node-token)
              curl -sfL https://get.k3s.io | K3S_URL=https://${aws_instance.k3s_master.private_ip}:6443 K3S_TOKEN=$K3S_TOKEN sh -
              EOF

  depends_on = [aws_instance.k3s_master]
} 