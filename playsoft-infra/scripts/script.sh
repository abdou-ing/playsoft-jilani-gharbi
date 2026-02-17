#!/bin/bash

set -e  # Exit on error

# ------------- CONFIG -------------------
HCLOUD_TOKEN=${HCLOUD_TOKEN:? "❌ ERROR: HCLOUD_TOKEN is not set!"}

SSH_KEY_NAME="jilani-key"
MY_IP="0.0.0.0/0"
TFVARS_FILE="env/dev.tfvars"
PKR_VARS_FILE="dev.pkrvars.hcl"
# ----------------------------------------

echo "🚀 Starting Packer & Terraform automation workflow..."
echo "-----------------------------------------------------"

# ---- PACKER BUILD BASTION #1 ----
echo "📦 Running packer build #1..."
cd ~/playsoft-jilani-gharbi/playsoft-infra/packer/bastion
packer build \
  -var "hcloud_token=$HCLOUD_TOKEN" \
  -var-file="$PKR_VARS_FILE" \
  .
 

echo "✅ Packer build bastion #1 complete."

# ---- PACKER BUILD GUACAMOLE #2 ----
echo "📦 Running packer build #2..."
cd ~/playsoft-jilani-gharbi/playsoft-infra/packer/guacamole
packer build \
  -var "hcloud_token=$HCLOUD_TOKEN" \
  -var-file="$PKR_VARS_FILE" \
  .

echo "✅ Packer build guacamole #2 complete."
# ---- TERRAFORM APPLY ----
echo "🌍 Running terraform apply..."
 cd ~/playsoft-jilani-gharbi/playsoft-infra/terraform

terraform apply \
  -var="ssh_key_name=$SSH_KEY_NAME" \
  -var="my_ip=$MY_IP" \
  -var-file="$TFVARS_FILE" \
  -auto-approve
echo "🎉 Deployment complete!"