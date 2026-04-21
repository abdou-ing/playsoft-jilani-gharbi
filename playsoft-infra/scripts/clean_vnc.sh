#!/bin/bash

# Exit immediately if any command fails
set -e

# -------------------------------------------------------------------
#                            CONFIGURATION
# -------------------------------------------------------------------

# Terraform directory
TF_DIR="/home/jilani/playsoft-jilani-gharbi/playsoft-infra/terraform-k8s"

# Ansible directory
ANSIBLE_DIR="/home/jilani/playsoft-jilani-gharbi/playsoft-infra/ansible"

# -------------------------------------------------------------------
echo "🧹 Starting VNC cleanup process..."
echo "-----------------------------------------------------"

# -------------------------------------------------------------------
#                       ANSIBLE — CLEANUP SETUP
# -------------------------------------------------------------------
echo "🌍 Running Ansible cleanup playbook (Proxmox Firewall)..."

cd "$ANSIBLE_DIR"

ansible-playbook cleanup_vnc.yml

# -------------------------------------------------------------------
#                       TERRAFORM — DESTROY VNC VMs
# -------------------------------------------------------------------
echo "🌍 Destroying VNC server VMs via Terraform..."

cd "$TF_DIR"

# Only destroy the VNC server module to keep the rest of the infra (K8s, Edge) intact
terraform destroy -var-file=env/dev.tfvars -target=module.vnc_server -auto-approve

echo "✅ VNC VMs destroyed."

# -------------------------------------------------------------------
echo "🎉 Cleanup complete!"
echo "-----------------------------------------------------"
