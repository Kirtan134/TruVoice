# This file handles the deployment of the TruVoice application to K3s
# This is a null_resource that runs after the K3s cluster is set up

# Store the kubeconfig in AWS Systems Manager Parameter Store
resource "aws_ssm_parameter" "kubeconfig" {
  name        = "/k3s/kubeconfig"
  description = "K3s kubeconfig for TruVoice application"
  type        = "SecureString"
  value       = "PLACEHOLDER" # This will be updated by the remote-exec provisioner
  overwrite   = true

  tags = merge(var.tags, {
    Name        = "k3s-kubeconfig-${var.environment}"
    Environment = var.environment
  })
}

resource "null_resource" "deploy_truvoice" {
  depends_on = [aws_instance.k3s_master, aws_instance.k3s_worker]

  triggers = {
    master_id = aws_instance.k3s_master.id
    environment = var.environment
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.k3s_master.public_ip
    }

    inline = [
      # Wait for K3s to be fully initialized
      "sleep 90",
      
      # Create namespace for the application
      "sudo kubectl create namespace truvoice-${var.environment} || true",
      
      # Copy existing Kubernetes manifests to master
      "mkdir -p ~/k8s-${var.environment}",
      
      # Get the kubeconfig and update the SSM parameter
      "KUBECONFIG=$(sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/${aws_instance.k3s_master.public_ip}/g')",
      "aws ssm put-parameter --name '/k3s/kubeconfig' --value \"$KUBECONFIG\" --type SecureString --overwrite"
    ]
  }

  # Copy the K8s manifests to the master node
  provisioner "file" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.k3s_master.public_ip
    }

    source      = "../k8s/"
    destination = "~/k8s-${var.environment}"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.k3s_master.public_ip
    }

    inline = [
      # Update environment-specific values
      "sed -i 's/namespace: truvoice/namespace: truvoice-${var.environment}/g' ~/k8s-${var.environment}/*.yaml",
      
      # Apply the Kubernetes manifests
      "sudo kubectl apply -f ~/k8s-${var.environment}/secrets.yaml -n truvoice-${var.environment}",
      "sudo kubectl apply -f ~/k8s-${var.environment}/deployment.yaml -n truvoice-${var.environment}",
      "sudo kubectl apply -f ~/k8s-${var.environment}/service.yaml -n truvoice-${var.environment}",
      "sudo kubectl apply -f ~/k8s-${var.environment}/ingress.yaml -n truvoice-${var.environment}",
      
      # Wait for the deployment to be ready
      "sudo kubectl rollout status deployment/truvoice -n truvoice-${var.environment} --timeout=300s"
    ]
  }
} 