#!/bin/bash
set -e

# -------------------------------------------------------------------
#                            CONFIGURATION
# -------------------------------------------------------------------

TF_DIR="/home/jilani/playsoft-jilani-gharbi/playsoft-infra/aws_terrafrom"
ANSIBLE_DIR="/home/jilani/playsoft-jilani-gharbi/playsoft-infra/ansible-amazon"

# Terraform variables file (override with: TFVARS_FILE=env/prod.tfvars ./aws_bootstrap_guacamole.sh)
TFVARS_FILE="${TFVARS_FILE:-env/dev.tfvars}"

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


terraform apply -var-file="${TFVARS_FILE}"

echo "📥 Exporting Terraform outputs to JSON..."
terraform output -json > tf_output.json

BASTION_IP=$(jq -r '.bastion_public_ip.value' tf_output.json)
CP_ENDPOINT=$(jq -r '.control_plane_endpoint.value' tf_output.json)
ALB_DNS=$(jq -r '.alb_dns_name.value' tf_output.json)
echo "✅ Terraform apply completed. bastion=${BASTION_IP} control_plane=${CP_ENDPOINT}"

# -------------------------------------------------------------------
#          WAIT FOR MASTER/WORKER INSTANCES TO APPEAR IN AWS
# -------------------------------------------------------------------
echo "⏳ Waiting for instances to show up in dynamic inventory..."

cd "${ANSIBLE_DIR}"
for i in $(seq 1 20); do
  HOST_COUNT=$(ansible-inventory -i inventory/aws_ec2.yml --list 2>/dev/null \
    | jq -r '(._meta.hostvars // {}) | keys | length')
  if [ "${HOST_COUNT}" -ge 1 ]; then
    echo "${HOST_COUNT} host(s) visible."
    break
  fi
  echo "   not ready yet (attempt ${i}/20), retrying in 15s..."
  sleep 15
done

# -------------------------------------------------------------------
#          WAIT FOR SSH TO ACTUALLY BE UP (bastion + master + worker)
# -------------------------------------------------------------------

echo "⏳ Waiting for SSH to come up on all hosts..."
ansible all -i inventory/aws_ec2.yml -m ansible.builtin.wait_for_connection -a "timeout=300"

# -------------------------------------------------------------------
#         ANSIBLE — CLUSTER + GUACAMOLE + VAULT AppRole DELIVERY
# -------------------------------------------------------------------

echo "🌍 Running Ansible playbook (cluster bootstrap + Guacamole + Vault + monitoring)..."


ansible-playbook -i inventory/aws_ec2.yml site.yml --tags k8s_cluster,k8s_vault,monitoring,prometheus,grafana

MONITORING_IP=$(jq -r '.monitoring_public_ip.value' tf_output.json)

echo "🎉 Deployment complete!"
echo "   SSH to bastion:    ssh -i ~/.ssh/jilani ubuntu@${BASTION_IP}"
echo "   Control plane:     ${CP_ENDPOINT}"
echo "   Guacamole:         http://${ALB_DNS}/guacamole/  (guacadmin/guacadmin -- change it)"
echo "   Grafana:           http://${MONITORING_IP}:3000/  (admin/admin -- change it, restricted to admin_cidr)"
echo "   Prometheus:        http://${MONITORING_IP}:9090/  (restricted to admin_cidr)"
