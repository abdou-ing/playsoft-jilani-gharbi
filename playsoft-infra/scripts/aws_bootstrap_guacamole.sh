#!/bin/bash

# Provisions the AWS self-managed cluster (aws_terrafrom) and deploys
# Kubernetes + Guacamole + the Vault AppRole secret_id onto it
# (ansible-amazon/site.yml, tags k8s_cluster + k8s_vault -- both always run,
# see VAULT_ROLE_ID/VAULT_SECRET_ID check below). AWS counterpart to
# hzn_guacamole_bootstrap.sh.
#
# Unlike the Hetzner workflow (generate_inventory.sh writing a static
# inventory.ini from tf_output.json), the worker ASG here has no stable IP
# list -- ansible-amazon uses the amazon.aws.aws_ec2 dynamic inventory
# plugin instead (inventory/aws_ec2.yml: region us-east-1, tag
# kubernetes_cluster=guacamole, matching env/dev.tfvars). So there's no
# inventory-generation step here: just terraform apply -> terraform
# output -json (read by ansible-amazon/group_vars/all.yml for
# bastion_public_ip / control_plane_endpoint) -> wait for the new
# instances to show up in AWS -> ansible-playbook site.yml.

# Exit immediately if any command fails
set -e

# -------------------------------------------------------------------
#                            CONFIGURATION
# -------------------------------------------------------------------

TF_DIR="/home/jilani/playsoft-jilani-gharbi/playsoft-infra/aws_terrafrom"
ANSIBLE_DIR="/home/jilani/playsoft-jilani-gharbi/playsoft-infra/ansible-amazon"

# Terraform variables file (override with: TFVARS_FILE=env/prod.tfvars ./aws_bootstrap_guacamole.sh)
TFVARS_FILE="${TFVARS_FILE:-env/dev.tfvars}"

# Vault AppRole bootstrap credentials -- required by the k8s_vault tag
# (roles/k8s-vault/tasks/vault_config.yml), which this script always runs.
# Fail fast here instead of burning a full terraform apply + cluster bootstrap
# only to hit the same assertion deep inside the playbook.
VAULT_ROLE_ID=${VAULT_ROLE_ID:? "❌ ERROR: VAULT_ROLE_ID is not set!"}
VAULT_SECRET_ID=${VAULT_SECRET_ID:? "❌ ERROR: VAULT_SECRET_ID is not set!"}

# -------------------------------------------------------------------
echo "🚀 Starting AWS Terraform + Ansible deployment workflow..."
echo "-----------------------------------------------------"

# -------------------------------------------------------------------
#                       TERRAFORM — AWS
# -------------------------------------------------------------------
echo "🌍 Running Terraform (${TFVARS_FILE})..."

cd "${TF_DIR}"
terraform init -input=false

# Deliberately interactive (no -auto-approve): this provisions real,
# billable AWS infra -- review the plan and confirm by hand. Pass
# -auto-approve yourself on the CLI if you want it unattended:
#   TFVARS_FILE=env/dev.tfvars terraform apply -var-file=... -auto-approve
terraform apply -var-file="${TFVARS_FILE}"

echo "📥 Exporting Terraform outputs to JSON..."
terraform output -json > tf_output.json

BASTION_IP=$(jq -r '.bastion_public_ip.value' tf_output.json)
CP_ENDPOINT=$(jq -r '.control_plane_endpoint.value' tf_output.json)
ALB_DNS=$(jq -r '.alb_dns_name.value' tf_output.json)
echo "✅ Terraform apply completed. bastion=${BASTION_IP} control_plane=${CP_ENDPOINT}"

# -------------------------------------------------------------------
#          LET THE NAT GATEWAY'S DATA PATH SETTLE
# -------------------------------------------------------------------
# Master/worker userdata starts installing packages (apt, pkgs.k8s.io)
# within seconds of boot -- if the apply above just created the NAT
# gateway, its API status flips to "available" well before its data
# path actually forwards traffic. Seen live: NAT created at T+0,
# instance egress still fully unreachable at T+70s, causing apt-get/curl
# in the userdata to fail outright and cloud-init to record a permanent
# error status for that boot. Terraform has no resource to wait on for
# this, so it's a plain sleep -- costs nothing on a run where the NAT
# already existed, cheap insurance against a failed userdata run on one
# where it didn't.
echo "⏳ Letting the NAT gateway settle before instances hit the internet..."
sleep 90

# -------------------------------------------------------------------
#          WAIT FOR MASTER/WORKER INSTANCES TO APPEAR IN AWS
# -------------------------------------------------------------------
# ansible-amazon has no static inventory to regenerate -- its dynamic
# inventory queries live EC2 state, which can lag a few seconds behind the
# ASG actually launching instances.
echo "⏳ Waiting for instances to show up in dynamic inventory..."

cd "${ANSIBLE_DIR}"
for i in $(seq 1 20); do
  HOST_COUNT=$(ansible-inventory -i inventory/aws_ec2.yml --list 2>/dev/null \
    | jq -r '(._meta.hostvars // {}) | keys | length')
  if [ "${HOST_COUNT}" -ge 1 ]; then
    echo "✅ ${HOST_COUNT} host(s) visible."
    break
  fi
  echo "   not ready yet (attempt ${i}/20), retrying in 15s..."
  sleep 15
done

# -------------------------------------------------------------------
#          WAIT FOR SSH TO ACTUALLY BE UP (bastion + master + worker)
# -------------------------------------------------------------------
# Being visible in the EC2 API ("running") happens well before sshd is
# actually accepting connections -- especially for master/worker, reached
# through the bastion's ProxyCommand hop, which itself needs to be up
# first. Skipping this leads to a confusing "UNKNOWN port 65535 timed out
# during banner exchange" mid-playbook, which then cascades (a host that
# fails one play gets dropped from every later play in the same run).
# wait_for_connection retries internally until timeout, so one ad-hoc call
# covers all hosts in parallel.
echo "⏳ Waiting for SSH to come up on all hosts..."
ansible all -i inventory/aws_ec2.yml -m ansible.builtin.wait_for_connection -a "timeout=300"

# -------------------------------------------------------------------
#         ANSIBLE — CLUSTER + GUACAMOLE + VAULT AppRole DELIVERY
# -------------------------------------------------------------------
# k8s_cluster runs common -> master -> worker -> k8s-addons, which stands up
# Kubernetes and deploys the Guacamole manifests (roles/master/files/,
# applied by roles/k8s-addons). k8s_vault (hosts: localhost) delivers the
# workload AppRole's secret_id into the cluster so the guacamole-vault
# SecretStore can authenticate -- always included here, never a separate
# step to remember.
echo "🌍 Running Ansible playbook (cluster bootstrap + Guacamole + Vault)..."

ansible-playbook -i inventory/aws_ec2.yml site.yml --tags k8s_cluster,k8s_vault

echo "🎉 Deployment complete!"
echo "   SSH to bastion:    ssh -i ~/.ssh/jilani ubuntu@${BASTION_IP}"
echo "   Control plane:     ${CP_ENDPOINT}"
echo "   Guacamole:         http://${ALB_DNS}/guacamole/  (guacadmin/guacadmin -- change it)"
