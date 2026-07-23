#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/terraform"
MANIFESTS_DIR="$SCRIPT_DIR/manifests"
ENV_TFVARS="${ENV_TFVARS:-env/dev.tfvars}"
LBC_CHART_VERSION="${LBC_CHART_VERSION:-1.8.1}"

for bin in terraform aws kubectl helm; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: $bin not found on PATH" >&2; exit 1; }
done

echo "==> Provisioning EKS cluster + VPC"
cd "$TERRAFORM_DIR"
terraform init -upgrade
terraform apply -auto-approve -var-file="$ENV_TFVARS"
echo "    OK"

REGION="$(terraform output -raw region 2>/dev/null || grep -E '^region' "$ENV_TFVARS" | cut -d'"' -f2)"
CLUSTER_NAME="$(terraform output -raw cluster_name)"
VPC_ID="$(terraform output -raw vpc_id)"
LBC_ROLE_ARN="$(terraform output -raw lb_controller_role_arn)"

echo "==> Pointing kubectl at $CLUSTER_NAME"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo "    OK"

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
    --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$LBC_ROLE_ARN"

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

echo "==> Deploying Guacamole"
RENDERED_DIR="$(mktemp -d)"
trap 'rm -rf "$RENDERED_DIR"' EXIT
cp "$MANIFESTS_DIR"/*.yaml "$RENDERED_DIR"/

VAULT_ROLE_ID="${VAULT_ROLE_ID:-ea989d3f-4b56-2c56-5b8f-187753cb1174}"
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

if [ -n "$LBC_ROLE_ARN" ]; then
  echo "==> Waiting for the ALB to be provisioned (this can take a couple minutes)"
  for i in $(seq 1 30); do
    ALB_HOST="$(kubectl get ingress guacamole-web -n guacamole -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
    [ -n "$ALB_HOST" ] && break
    sleep 10
  done
fi

echo ""
echo "Guacamole:"
if [ -n "${ALB_HOST:-}" ]; then
  echo "  http://$ALB_HOST/guacamole"
elif [ -n "$LBC_ROLE_ARN" ]; then
  echo "  ALB hostname not ready yet -- check: kubectl get ingress -n guacamole"
else
  echo "  Not reachable yet -- phase 2 (LB controller + ebs-csi) still pending, see above."
fi
