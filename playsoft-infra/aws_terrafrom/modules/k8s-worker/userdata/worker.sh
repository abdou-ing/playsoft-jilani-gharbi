#!/bin/bash
###############################################################
# WORKER user-data  (Terraform templatefile)
#
# Node prep (containerd/kubeadm/kubelet/kubectl) runs at boot here
# since ami_id is empty (no baked AMI). Workers do NOT self-join --
# the Ansible control node discovers the new worker (dynamic aws_ec2
# inventory) and runs `kubeadm join` on it via SSH.
#
# Injected vars:
#   master_endpoint - control-plane IP (host for :6443)
#   region          - AWS region
#   cluster_name    - cluster name
#
# Plain shell $VAR / $(cmd) is untouched by templatefile() and must
# be left as a single $ -- do not double it to $$VAR, since a
# doubled dollar sign not followed by a brace passes through
# literally (bash syntax error).
###############################################################
set -euxo pipefail

# --- 0. Node prep: containerd + kubeadm/kubelet/kubectl (no baked AMI) ---
echo "[INFO] Disable swap"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[INFO] Install dependencies"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg python3

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

# In the Ansible-driven design, workers do NOT self-join here. The
# Ansible control node discovers the new worker (dynamic aws_ec2
# inventory) and runs `kubeadm join` on it via SSH.
#
# (If you prefer self-join instead of Ansible-join, put your
#  `kubeadm join ${master_endpoint}:6443 ...` command here.)
