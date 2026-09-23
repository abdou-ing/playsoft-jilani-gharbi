#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform/aws-eks"
MANIFESTS_DIR="$SCRIPT_DIR/manifests"
ENV_TFVARS="${ENV_TFVARS:-env/dev.tfvars}"
ENV_SECRETS_TFVARS="${ENV_SECRETS_TFVARS:-env/dev.secrets.tfvars}"
LBC_CHART_VERSION="${LBC_CHART_VERSION:-1.8.1}"

# Bail out early if any required CLI is missing, instead of failing mid-deploy.
for bin in terraform aws kubectl helm; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: $bin not found on PATH" >&2; exit 1; }
done

# Create/update the VPC, EKS cluster, node group and (if role ARNs are set) addons.
echo "==> Provisioning EKS cluster + VPC"
cd "$TERRAFORM_DIR"
terraform init -upgrade
TF_VAR_FILE_ARGS=(-var-file="$ENV_TFVARS")
if [ -f "$ENV_SECRETS_TFVARS" ]; then
  TF_VAR_FILE_ARGS+=(-var-file="$ENV_SECRETS_TFVARS")
else
  echo "    NOTE: $ENV_SECRETS_TFVARS not found -- proxmox_api_token_id/secret must come from"
  echo "    elsewhere (TF_VAR_proxmox_api_token_id / TF_VAR_proxmox_api_token_secret env vars,"
  echo "    or a different -var-file) if vnc_server_count/ssh_server_count > 0."
fi
terraform apply -auto-approve "${TF_VAR_FILE_ARGS[@]}"
echo "    OK"

# Export outputs to JSON for ansible/aws-eks (guacamole_connection, guacamole_url,
# ssh_setup, vnc_setup all read this for ssh_vm_ids/ssh_vm_ips/vnc_vm_ids/
# vnc_vm_ips) -- same pattern as scripts/hzn_guacamole_bootstrap.sh.
echo "📥 Exporting Terraform outputs to JSON..."
terraform output -json > tf_output.json
echo "    OK"

# Pull values out of Terraform state for the steps below (kubeconfig, Helm, ALB wait).
REGION="$(terraform output -raw region 2>/dev/null || grep -E '^region' "$ENV_TFVARS" | cut -d'"' -f2)"
CLUSTER_NAME="$(terraform output -raw cluster_name)"
VPC_ID="$(terraform output -raw vpc_id)"
LBC_ROLE_ARN="$(terraform output -raw lb_controller_role_arn)"

# Switch the local kubectl context to the cluster just created/updated.
echo "==> Pointing kubectl at $CLUSTER_NAME"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo "    OK"

# Poll until every node has joined and gone Ready before deploying anything onto them.
echo "==> Waiting for nodes to be Ready"
for i in $(seq 1 30); do
  NOT_READY="$(kubectl get nodes --no-headers 2>/dev/null | grep -c 'NotReady' || true)"
  READY_COUNT="$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo 0)"
  if [ "$READY_COUNT" -gt 0 ] && [ "$NOT_READY" -eq 0 ]; then
    break
  fi
  sleep 10
done
kubectl get nodes
echo "    OK"

# Phase-2 gate: only install the LB Controller once its IAM role ARN exists.
if [ -n "$LBC_ROLE_ARN" ]; then
  echo "==> Installing the AWS Load Balancer Controller"
  helm repo add eks https://aws.github.io/eks-charts >/dev/null
  helm repo update eks >/dev/null
  helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
    --version "$LBC_CHART_VERSION" \
    -n kube-system \
    --set clusterName="$CLUSTER_NAME" \
    --set region="$REGION" \
    --set vpcId="$VPC_ID" \
    --set serviceAccount.create=true \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$LBC_ROLE_ARN" \
    --set enableWaf=false \
    --set enableWafv2=false \
    --set enableShield=false



  # Confirm the controller pod actually comes up before moving on.
  echo "==> Waiting for the controller to come up"
  kubectl -n kube-system rollout status deployment/aws-load-balancer-controller --timeout=180s
  echo "    OK"
else
  echo "==> Skipping the AWS Load Balancer Controller (lb_controller_role_arn not set yet)"
  echo "    This is expected on the first (phase 1) run -- send Abdallah:"
  echo "      terraform output cluster_oidc_issuer_url"
  echo "    then fill in ebs_csi_role_arn/lb_controller_role_arn in $ENV_TFVARS and re-run."
  echo "    The Guacamole manifests below will still apply, but the Ingress"
  echo "    won't get an ALB and the postgres PVC won't bind until then."
fi

# Install the operator that will pull postgres/redis/backup secrets from Vault.
echo "==> Installing the External Secrets Operator"
helm repo add external-secrets https://charts.external-secrets.io >/dev/null
helm repo update external-secrets >/dev/null

# Pinned chart version (2.7.0) so reruns don't silently pick up a CRD bump.
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --version 2.7.0
kubectl -n external-secrets rollout status deployment/external-secrets --timeout=180s
kubectl -n external-secrets rollout status deployment/external-secrets-webhook --timeout=180s
kubectl -n external-secrets rollout status deployment/external-secrets-cert-controller --timeout=180s

# Deployment Available can lag the webhook's actual Service endpoint by a beat --
# wait for a real endpoint or the SecretStore/ExternalSecret apply below 404s.
echo "==> Waiting for the webhook Service to have an endpoint"
for i in $(seq 1 30); do
  [ -n "$(kubectl get endpoints external-secrets-webhook -n external-secrets -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ] && break
  sleep 2
done
echo "    OK"

# Apply every manifest in eks/manifests/ (namespace, postgres, guacd, web, addons...).
echo "==> Deploying Guacamole"
RENDERED_DIR="$(mktemp -d)"
trap 'rm -rf "$RENDERED_DIR"' EXIT
cp "$MANIFESTS_DIR"/*.yaml "$RENDERED_DIR"/

# Render 07-vault-secrets.yaml.tmpl by substituting in the Vault AppRole ID (no Jinja2 here).
VAULT_ROLE_ID="${VAULT_ROLE_ID:?VAULT_ROLE_ID must be set}"
sed "s|__VAULT_ROLE_ID__|$VAULT_ROLE_ID|" "$MANIFESTS_DIR/07-vault-secrets.yaml.tmpl" \
  > "$RENDERED_DIR/07-vault-secrets.yaml"

kubectl apply -f "$RENDERED_DIR"
kubectl config set-context --current --namespace=guacamole
echo "    OK"

if [ -n "${VAULT_SECRET_ID:-}" ]; then
  echo "==> Delivering the workload AppRole secret_id"
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: vault-approle-creds
  namespace: guacamole
stringData:
  secretId: "$VAULT_SECRET_ID"
EOF
  echo "    OK"
else
  echo "==> Skipping vault-approle-creds Secret (VAULT_SECRET_ID not set)"
  echo "    ExternalSecrets will sit and retry until you deliver it, e.g.:"
  echo "    VAULT_SECRET_ID=... ./deploy.sh"
fi

# Only worth waiting for an ALB hostname if the LB Controller was actually installed above.
if [ -n "$LBC_ROLE_ARN" ]; then
  echo "==> Waiting for the ALB to be provisioned (this can take a couple minutes)"
  for i in $(seq 1 30); do
    ALB_HOST="$(kubectl get ingress guacamole-web -n guacamole -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
    [ -n "$ALB_HOST" ] && break
    sleep 10
  done
fi

# ansible/aws-eks: Proxmox access setup (ssh_setup/vnc_setup) + Guacamole
# connection/user registration + direct-access URL. See ansible/aws-eks/site.yml.
# One flag gates the whole thing; set RUN_ANSIBLE_EKS=0 to skip entirely
# (e.g. infra-only runs, or environments without ansible installed).
RUN_ANSIBLE_EKS="${RUN_ANSIBLE_EKS:-1}"
ANSIBLE_EKS_DIR="$SCRIPT_DIR/../ansible/aws-eks"

if [ "$RUN_ANSIBLE_EKS" = "1" ] && ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "==> Skipping ansible/aws-eks (ansible-playbook not found on PATH)"
  echo "    Run it manually once ansible is available -- see ansible/aws-eks/site.yml tags:"
  echo "    access_setup, guacamole_connection, guacamole_url"
  RUN_ANSIBLE_EKS=0
fi

# Proxmox-side access for candidate target VMs (NAT/VNC) -- independent of
# the ALB/EKS state above, same physical Proxmox host regardless of phase.
if [ "$RUN_ANSIBLE_EKS" = "1" ]; then
  echo "==> Configuring Proxmox access (ssh_setup/vnc_setup) for candidate target VMs"
  (cd "$ANSIBLE_EKS_DIR" && ansible-playbook site.yml --tags access_setup) \
    || echo "    Proxmox access setup failed -- rerun manually:
    (cd ../ansible/aws-eks && ansible-playbook site.yml --tags access_setup)"
fi

# Register Guacamole connections/users and print the direct-access URL, same
# as the Hetzner deploy (ansible/roles/guacamole_connection + guacamole_url).
# ALB_HOST existing above just means the hostname was assigned -- DNS still
# needs to propagate and the target group still needs to pass health checks
# before it actually answers. ansible/aws-eks's guacamole_connection/guacamole_url
# roles retry the real HTTP endpoint themselves (up to ~10 min) before doing
# anything else, so it's safe to call as soon as ALB_HOST is known.
if [ "$RUN_ANSIBLE_EKS" = "1" ] && [ -n "${ALB_HOST:-}" ]; then
  echo "==> Waiting for Guacamole to answer behind the ALB, then provisioning connections/users"
  (cd "$ANSIBLE_EKS_DIR" && ansible-playbook site.yml \
    --tags guacamole_connection,guacamole_url \
    -e "eks_alb_hostname=$ALB_HOST") \
    || echo "    Guacamole connection/user provisioning failed or timed out -- rerun manually:
    (cd ../ansible/aws-eks && ansible-playbook site.yml --tags guacamole_connection,guacamole_url -e eks_alb_hostname=$ALB_HOST)"
elif [ "$RUN_ANSIBLE_EKS" = "1" ]; then
  echo "==> Skipping Guacamole connection/user provisioning (no ALB hostname yet)"
  echo "    Rerun once one exists:"
  echo "    (cd ../ansible/aws-eks && ansible-playbook site.yml --tags guacamole_connection,guacamole_url -e eks_alb_hostname=<hostname>)"
fi

# Final summary: print the reachable URL, or explain why it isn't reachable yet.
echo ""
echo "Guacamole:"
if [ -n "${ALB_HOST:-}" ]; then
  echo "  http://$ALB_HOST/guacamole"
elif [ -n "$LBC_ROLE_ARN" ]; then
  echo "  ALB hostname not ready yet -- check: kubectl get ingress -n guacamole"
else
  echo "  Not reachable yet -- phase 2 (LB controller + ebs-csi) still pending, see above."
fi
