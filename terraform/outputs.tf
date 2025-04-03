output "k3s_master_public_ip" {
  description = "Public IP of the K3s master node"
  value       = aws_instance.k3s_master.public_ip
}

output "k3s_workers_public_ips" {
  description = "Public IPs of the K3s worker nodes"
  value       = aws_instance.k3s_worker[*].public_ip
}

output "k3s_master_private_ip" {
  description = "Private IP of the K3s master node"
  value       = aws_instance.k3s_master.private_ip
}

output "k3s_workers_private_ips" {
  description = "Private IPs of the K3s worker nodes"
  value       = aws_instance.k3s_worker[*].private_ip
}

output "kubectl_config_command" {
  description = "Command to copy K3s kubeconfig from master node"
  value       = "ssh -i /path/to/private_key ubuntu@${aws_instance.k3s_master.public_ip} sudo cat /etc/rancher/k3s/k3s.yaml > kubeconfig.yaml && sed -i 's/127.0.0.1/${aws_instance.k3s_master.public_ip}/g' kubeconfig.yaml"
} 