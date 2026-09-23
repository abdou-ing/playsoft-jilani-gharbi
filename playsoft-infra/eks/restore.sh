#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform/aws-eks"
ENV_TFVARS="${ENV_TFVARS:-env/dev.tfvars}"
NAMESPACE="guacamole"
# 1 = latest backup, 2 = second-most-recent, etc.
BACKUP_INDEX="${BACKUP_INDEX:-1}"

# Bail out early if any required CLI is missing.
for bin in terraform aws kubectl mc; do
  command -v "$bin" >/dev/null 2>&1 || { echo "ERROR: $bin not found on PATH" >&2; exit 1; }
done

# Pull cluster name/region out of Terraform state, same as deploy.sh/destroy.sh.
cd "$TERRAFORM_DIR"
CLUSTER_NAME="$(terraform output -raw cluster_name)"
REGION="$(terraform output -raw region 2>/dev/null || grep -E '^region' "$ENV_TFVARS" | cut -d'"' -f2)"

echo "==> Pointing kubectl at $CLUSTER_NAME"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo "    OK"

# Pull the same credentials ExternalSecrets already synced from Vault --
# same S3 bucket + Postgres role hzn's backup-cronjob and db-restore role use.
echo "==> Reading backup-s3-secret and postgres-secret from the cluster"
S3_ENDPOINT="$(kubectl get secret backup-s3-secret -n "$NAMESPACE" -o jsonpath='{.data.endpoint}' | base64 -d)"
S3_ACCESS_KEY="$(kubectl get secret backup-s3-secret -n "$NAMESPACE" -o jsonpath='{.data.access-key}' | base64 -d)"
S3_SECRET_KEY="$(kubectl get secret backup-s3-secret -n "$NAMESPACE" -o jsonpath='{.data.secret-key}' | base64 -d)"
PG_USER="$(kubectl get secret postgres-secret -n "$NAMESPACE" -o jsonpath='{.data.postgres-user}' | base64 -d)"
PG_PASSWORD="$(kubectl get secret postgres-secret -n "$NAMESPACE" -o jsonpath='{.data.postgres-password}' | base64 -d)"
PG_DB="$(kubectl get secret postgres-secret -n "$NAMESPACE" -o jsonpath='{.data.postgres-db}' | base64 -d)"
echo "    OK"

# Find the hzn-produced backup at BACKUP_INDEX from the end (1 = latest) --
# bucket root, excluding the aws/ prefix EKS's own nightly cronjob
# (06-backup-cronjob.yaml) writes to.
echo "==> Locating backup #$BACKUP_INDEX from the latest"
mc alias set backup-target "$S3_ENDPOINT" "$S3_ACCESS_KEY" "$S3_SECRET_KEY" >/dev/null
LATEST="$(mc find backup-target/guacamole-backup-dev/ --name "guacdb-*.sql.gz" | grep -v '/aws/' | sort | tail -n "$BACKUP_INDEX" | head -n1)"
[ -n "$LATEST" ] || { echo "ERROR: no guacdb-*.sql.gz backup found at index $BACKUP_INDEX in guacamole-backup-dev/" >&2; exit 1; }
echo "    $LATEST"


echo "==> Dropping and recreating the public schema on $PG_DB"
kubectl exec -n "$NAMESPACE" deploy/postgres -- \
  env PGPASSWORD="$PG_PASSWORD" PGOPTIONS="--client-min-messages=warning" \
  psql -q -U "$PG_USER" -d "$PG_DB" \
  -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" >/dev/null
echo "    OK"

# Stream straight from S3 -> gunzip -> psql, no local temp file.
# Command tags (CREATE TABLE, COPY n, ...) go to stdout and are discarded;
# real errors go to stderr and still show, and `pipefail` still catches them.
echo "==> Restoring $LATEST into deploy/postgres"
mc cat "$LATEST" | gunzip -c | \
  kubectl exec -i -n "$NAMESPACE" deploy/postgres -- \
  env PGPASSWORD="$PG_PASSWORD" PGOPTIONS="--client-min-messages=warning" \
  psql -q -U "$PG_USER" -d "$PG_DB" >/dev/null
echo "    OK"
