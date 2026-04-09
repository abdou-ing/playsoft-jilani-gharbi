#!/bin/bash
set -e

echo "[INFO] Disable swap"
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

echo "[INFO] Install dependencies"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg

echo "[INFO] Add Kubernetes repository"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list   # helps tools such as command-not-found to work correctly

echo "[INFO] Install containerd + Kubernetes tools"
sudo apt-get update
apt-get install -y containerd kubelet kubeadm kubectl
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

echo "[INFO] Enable & restart kubelet"
systemctl enable kubelet
# systemctl restart kubelet

echo "[INFO] Verify containerd config"
grep SystemdCgroup /etc/containerd/config.toml | tee -a /tmp/containerd_config_check.log

echo "[INFO] Kubernetes node is READY for cluster initialization"