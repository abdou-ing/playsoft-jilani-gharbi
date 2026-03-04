#!/bin/bash

# Exit immediately if any command fails
set -e

# -------------------------------------------------------------------
#                            CONFIGURATION
# -------------------------------------------------------------------

# Ensure Hetzner Cloud token is defined
HCLOUD_TOKEN=${HCLOUD_TOKEN:? "❌ ERROR: HCLOUD_TOKEN is not set!"}

# SSH key name used by Terraform
SSH_KEY_NAME="jilani-key"

# Allowed IP for firewall rules (currently wide-open)
MY_IP="0.0.0.0/0"

# Terraform variables file
TFVARS_FILE="env/dev.tfvars"

# Packer variables file
PKR_VARS_FILE="dev.pkrvars.hcl"

# -------------------------------------------------------------------
echo "🚀 Starting Packer & Terraform automation workflow..."
echo "-----------------------------------------------------"

# -------------------------------------------------------------------
#                       PACKER BUILD — BASTION
# -------------------------------------------------------------------
echo "📦 Running Packer build for Bastion (#1)..."

cd ~/playsoft-jilani-gharbi/playsoft-infra/packer/bastion

# packer build \
#   -var "hcloud_token=$HCLOUD_TOKEN" \
#   -var-file="$PKR_VARS_FILE" \
#   .

echo "✅ Packer build for Bastion completed."

# -------------------------------------------------------------------
#                     PACKER BUILD — GUACAMOLE
# -------------------------------------------------------------------
echo "📦 Running Packer build for Guacamole (#2)..."

cd ~/playsoft-jilani-gharbi/playsoft-infra/packer/guacamole

# packer build \
#   -var "hcloud_token=$HCLOUD_TOKEN" \
#   -var-file="$PKR_VARS_FILE" \
#   .

echo "✅ Packer build for Guacamole completed."

# -------------------------------------------------------------------
#                       TERRAFORM — HETZNER CLOUD
# -------------------------------------------------------------------
echo "🌍 Running Terraform for Hetzner servers..."

cd ~/playsoft-jilani-gharbi/playsoft-infra/terraform

terraform apply \
  -var="ssh_key_name=$SSH_KEY_NAME" \
  -var="my_ip=$MY_IP" \
  -var-file="$TFVARS_FILE" \
  -auto-approve

echo "📥 Exporting Terraform outputs to JSON..."
terraform output -json > tf_output.json

echo "✅ Terraform apply completed."

# -------------------------------------------------------------------
#                       TERRAFORM — PROXMOX VMS
# -------------------------------------------------------------------
echo "🌍 Running Terraform for Proxmox VMs..."

cd ~/playsoft-jilani-gharbi/playsoft-infra/terraform/modules/vnc-server

terraform apply -auto-approve

echo "📥 Exporting Terraform outputs to JSON..."
terraform output -json > tf_output.json

echo "✅ Proxmox Terraform apply completed."

# -------------------------------------------------------------------
#                       ANSIBLE — PROXMOX CONFIGURATION
# -------------------------------------------------------------------

echo "🌍 Running Ansible playbook to configure Proxmox VMs..."
cd ~/playsoft-jilani-gharbi/playsoft-infra/ansible
ansible-playbook proxmox-vnc-setup.yml
echo "✅ Proxmox VMs configured successfully."

# -------------------------------------------------------------------
#                       ANSIBLE — GUACAMOLE SETUP
# -------------------------------------------------------------------
echo "🌍 Running Ansible playbook to create VNC connections..."

cd ~/playsoft-jilani-gharbi/playsoft-infra/ansible

# Background port-forwarding for Guacamole web UI
ssh -o StrictHostKeyChecking=accept-new guacamole \
  "setsid kubectl port-forward -n guacamole svc/guacamole-web 8080:8080 --address 0.0.0.0 >/dev/null 2>&1 < /dev/null &"


ansible-playbook guacamole-connection.yml

echo "🎉 Deployment complete!"