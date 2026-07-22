#!/bin/bash
###############################################################
# MASTER user-data  (Terraform templatefile)
#
# Node prep (containerd/kubeadm/kubelet/kubectl) runs at boot here
# since ami_id is empty (no baked AMI) -- fill in step 2 with your
# `kubeadm init` once you're ready to actually bootstrap the cluster.
#
# Terraform injects these variables (substituted before the
# instance boots):
#
#   master_endpoint - fixed private IP (var.master_private_ip) for
#                     --control-plane-endpoint / kubeadm join
#   region          - AWS region
#   cluster_name    - cluster name
#
# The control-plane endpoint is this instance's own private IP,
# pinned in Terraform (aws_instance.master.private_ip) rather than
# fronted by a load balancer -- since master_count is hard-locked to
# 1, there's nothing to load-balance across, and pinning the IP
# means it survives a `terraform apply`-driven replace with no
# in-instance AWS API calls (and therefore no instance IAM role).
#
# NOTE: because this file goes through templatefile(), plain shell
# $VAR / $(cmd) is untouched and must be left as a single $ -- do
# not double it to $$VAR / $$(cmd), since Terraform's templatefile()
# only treats a dollar-brace pair specially and otherwise passes a
# doubled dollar sign through literally (bash syntax error).
###############################################################
set -euxo pipefail

REGION="${region}"
ENDPOINT="${master_endpoint}"

# --- 0. Node prep: containerd + kubeadm/kubelet/kubectl (no baked AMI) ---
echo "[INFO] Disable swap"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[INFO] Install dependencies"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg

echo "[INFO] Add Kubernetes repository"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
chmod 644 /etc/apt/sources.list.d/kubernetes.list

echo "[INFO] Install containerd + Kubernetes tools + node_exporter"
apt-get update
apt-get install -y containerd kubelet kubeadm kubectl prometheus-node-exporter
apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Configure containerd"
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl enable containerd
systemctl restart containerd

echo "[INFO] Configure kernel modules"
cat <<EOF >/etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[INFO] Configure sysctl"
cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo "[INFO] Enable kubelet"
systemctl enable kubelet

echo "[INFO] Kubernetes node is READY for cluster initialization"

# --- 1. YOUR kubeadm init goes here ---
# Example (replace with your real script):
#
# kubeadm init \
#   --control-plane-endpoint "$ENDPOINT:6443" \
#   --pod-network-cidr=10.244.0.0/16
#
# export KUBECONFIG=/etc/kubernetes/admin.conf
# kubectl apply -f /opt/cni/flannel.yaml
