#!/bin/bash
set -e

HCLOUD_TOKEN="${HCLOUD_TOKEN:?ERROR: HCLOUD_TOKEN env var is not set}"
PROJECT_DIR="/opt/infra/prometheus"

echo "==> Configuring Prometheus"
cp "$PROJECT_DIR/config/prometheus.yml" /etc/prometheus/prometheus.yml
cp "$PROJECT_DIR/config/alerts.yml"     /etc/prometheus/alerts.yml
systemctl reload prometheus
echo "    OK"

echo "==> Configuring AlertManager"
mkdir -p /var/lib/alertmanager
cp "$PROJECT_DIR/config/alertmanager.yml" /etc/alertmanager/alertmanager.yml
sed "s|REPLACE_WITH_TOKEN|$HCLOUD_TOKEN|" "$PROJECT_DIR/systemd/alertmanager.service" \
  > /etc/systemd/system/alertmanager.service
systemctl daemon-reload
systemctl enable --now alertmanager
echo "    OK"

echo "==> Configuring Autoscaler"
sed "s|REPLACE_WITH_TOKEN|$HCLOUD_TOKEN|" "$PROJECT_DIR/systemd/autoscaler.service" \
  > /etc/systemd/system/autoscaler.service
systemctl daemon-reload
systemctl enable --now autoscaler
echo "    OK"

echo "==> Initialising Terraform"
cd "$PROJECT_DIR/terraform"
export HCLOUD_TOKEN="$HCLOUD_TOKEN"
terraform init -upgrade
terraform apply -auto-approve -var-file=env/dev.tfvars
echo "    OK"

echo ""
echo "Pipeline ready:"
echo "  Prometheus  → http://$(curl -s http://169.254.169.254/hetzner/v1/metadata/public-ipv4 2>/dev/null || echo '<bastion-ip>'):9090"
echo "  AlertManager→ http://$(curl -s http://169.254.169.254/hetzner/v1/metadata/public-ipv4 2>/dev/null || echo '<bastion-ip>'):9093"
echo ""
echo "Test: ssh -i /root/.ssh/jilani root@10.20.0.10 'stress --cpu 4 --timeout 360'"
