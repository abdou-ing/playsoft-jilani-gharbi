#!/bin/bash
set -e

# Install dependencies
apt update
apt install -y curl git docker.io

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x kind
mv kind /usr/local/bin/kind

# Enable Docker
systemctl enable --now docker

# Clone project
mkdir -p /opt
git clone -b dev https://github.com/abdou-ing/playsoft-jilani-gharbi.git /opt/playsoft-jilani-gharbi
cd /opt/playsoft-jilani-gharbi/apache_guacamole_k8s-master

# Create Kind cluster
kind create cluster --config kind-config.yaml --name guacamole-cluster

# Deploy Guacamole
cd /opt/playsoft-jilani-gharbi/apache_guacamole_k8s-master/guacamole
kubectl apply -f .

#rm -f /etc/systemd/network/10-*.network
#rm -f /etc/systemd/resolved.conf
