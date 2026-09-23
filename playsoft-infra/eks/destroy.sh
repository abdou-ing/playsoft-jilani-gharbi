#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform/aws-eks"
ENV_TFVARS="${ENV_TFVARS:-env/dev.tfvars}"
ENV_SECRETS_TFVARS="${ENV_SECRETS_TFVARS:-env/dev.secrets.tfvars}"

for bin in terraform aws kubectl; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: $bin not found on PATH" >&2; exit 1; }
done

cd "$TERRAFORM_DIR"

if [ -z "$(terraform state list 2>/dev/null)" ]; then
  echo "Nothing in Terraform state -- infrastructure is already destroyed."
  exit 0
fi

CLUSTER_NAME="$(terraform output -raw cluster_name 2>/dev/null || true)"
REGION="$(terraform output -raw region 2>/dev/null || grep -E '^region' "$ENV_TFVARS" | cut -d'"' -f2)"


if [ -n "$CLUSTER_NAME" ] && aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" >/dev/null 2>&1; then
  echo "==> Pointing kubectl at $CLUSTER_NAME"
  aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

  echo "==> Deleting the guacamole-web Ingress (waiting for its ALB to be torn down)"
  echo "    This can take a couple of minutes -- kubectl blocks until the AWS Load Balancer"
  echo "    Controller has deleted the real ALB/target-group/listener and removed the"
  echo "    Ingress's finalizer."
  if ! kubectl delete ingress -n guacamole --all --ignore-not-found --timeout=240s; then
    echo "WARNING: Ingress deletion didn't finish in time -- the ALB may end up orphaned"
    echo "         once the cluster is destroyed. If 'terraform destroy' below gets stuck"
    echo "         destroying subnets/IGW for more than a couple minutes, check:"
    echo "           aws elbv2 describe-load-balancers --region $REGION"
    echo "         and delete any leftover k8s-guacamol-* load balancer manually."
  fi
  echo "    OK"
else
  echo "==> Cluster not reachable (already gone or never came up) -- skipping Ingress cleanup"
fi

echo "==> Destroying EKS cluster + VPC"
TF_VAR_FILE_ARGS=(-var-file="$ENV_TFVARS")
if [ -f "$ENV_SECRETS_TFVARS" ]; then
  TF_VAR_FILE_ARGS+=(-var-file="$ENV_SECRETS_TFVARS")
fi
terraform destroy -auto-approve "${TF_VAR_FILE_ARGS[@]}"
echo "    OK"
