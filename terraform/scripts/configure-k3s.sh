#!/bin/bash

# Script to handle K3s master and worker node configuration
# This script should be run after Terraform has provisioned the instances

set -e

# Get input arguments
MASTER_IP=$1
PRIVATE_KEY=$2

if [ -z "$MASTER_IP" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Usage: $0 <master_ip> <private_key_path>"
  exit 1
fi

echo "Waiting for K3s to be installed on master..."
sleep 60  # Give K3s time to install

# Retrieve the K3s token from the master node
echo "Retrieving K3s token from master node..."
TOKEN=$(ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no ubuntu@"$MASTER_IP" "sudo cat /var/lib/rancher/k3s/server/node-token")

# Retrieve kubeconfig from the master node
echo "Retrieving kubeconfig from master node..."
ssh -i "$PRIVATE_KEY" -o StrictHostKeyChecking=no ubuntu@"$MASTER_IP" "sudo cat /etc/rancher/k3s/k3s.yaml" > kubeconfig.yaml
sed -i "s/127.0.0.1/$MASTER_IP/g" kubeconfig.yaml
chmod 600 kubeconfig.yaml

echo "K3s Token: $TOKEN"
echo "Kubeconfig saved to ./kubeconfig.yaml"
echo ""
echo "To join a worker node manually:"
echo "curl -sfL https://get.k3s.io | K3S_URL=https://$MASTER_IP:6443 K3S_TOKEN=$TOKEN sh -"
echo ""
echo "To use kubectl with this cluster:"
echo "export KUBECONFIG=$(pwd)/kubeconfig.yaml" 