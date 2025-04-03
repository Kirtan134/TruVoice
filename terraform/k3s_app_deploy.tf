# This file handles the deployment of the TruVoice application to K3s
# This is a null_resource that runs after the K3s cluster is set up

resource "null_resource" "deploy_truvoice" {
  depends_on = [aws_instance.k3s_master, aws_instance.k3s_worker]

  triggers = {
    master_id = aws_instance.k3s_master.id
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
      "sleep 60",
      
      # Create namespace for the application
      "sudo kubectl create namespace truvoice",
      
      # Copy existing Kubernetes manifests to master
      "mkdir -p ~/k8s"
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
    destination = "~/k8s"
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.private_key_path)
      host        = aws_instance.k3s_master.public_ip
    }

    inline = [
      # Apply the Kubernetes manifests
      "sudo kubectl apply -f ~/k8s/secrets.yaml -n truvoice",
      "sudo kubectl apply -f ~/k8s/deployment.yaml -n truvoice",
      "sudo kubectl apply -f ~/k8s/service.yaml -n truvoice",
      "sudo kubectl apply -f ~/k8s/ingress.yaml -n truvoice",
      
      # Wait for the deployment to be ready
      "sudo kubectl rollout status deployment/truvoice -n truvoice --timeout=300s"
    ]
  }
} 