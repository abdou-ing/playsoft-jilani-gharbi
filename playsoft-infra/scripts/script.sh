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

# Terraform variables file
TFVARS_FILE="env/dev.tfvars"

# Packer variables file
PKR_VARS_FILE="dev.pkrvars.hcl"

# -------------------------------------------------------------------
echo "🚀 Starting Packer & Terraform automation workflow..."
echo "-----------------------------------------------------"

# -------------------------------------------------------------------
#                       PACKER BUILD — K8S CLUSTER
# -------------------------------------------------------------------
echo "📦 Running Packer build for k8s-cluster (#1)..."

cd ~/playsoft-jilani-gharbi/playsoft-infra/packer/k8s-cluster

# packer build . 

echo "✅ Packer build for k8s-cluster completed."

# -------------------------------------------------------------------
#                       TERRAFORM — HETZNER CLOUD
# -------------------------------------------------------------------
echo "🌍 Running Terraform for Hetzner servers..."

cd ~/playsoft-jilani-gharbi/playsoft-infra/terraform-k8s

#terraform apply -var-file=env/dev.tfvars -auto-approve

cd ~/playsoft-jilani-gharbi/playsoft-infra/terraform-k8s

echo "📥 Exporting Terraform outputs to JSON..."
terraform output -json > tf_output.json

echo "✅ Terraform apply completed."


# -------------------------------------------------------------------
#                       ANSIBLE — FULL DEPLOYMENT
# -------------------------------------------------------------------

echo "🌍 Running Ansible playbook for full configuration..."
cd ~/playsoft-jilani-gharbi/playsoft-infra/ansible
ansible-playbook site.yml --tags "access_setup,k8s_cluster,guacamole_connection,guacamole_url"




echo "🎉 Deployment complete!"