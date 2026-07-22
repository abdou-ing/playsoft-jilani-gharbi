#!/bin/bash
###############################################################
# BASTION user-data  (Terraform templatefile)
#
# Installs nginx as a reverse proxy so the cluster's app ALB is
# reachable through this bastion's single public IP, instead of
# hitting the ALB directly -- mirrors terraform-hzn's edge/bastion
# nginx reverse proxy (cloud-init/edge.yaml).
#
# Injected vars:
#   alb_dns_name - the app ALB's public DNS name
#
# NOTE: because this file goes through templatefile(), plain shell
# $VAR / $(cmd) is untouched and must be left as a single $ -- do
# not double it to $$VAR, since a doubled dollar sign not followed
# by a brace passes through literally (bash syntax error). The
# nginx variables inside the heredoc below (\$http_upgrade etc.)
# use a backslash, not $$ -- that's escaping bash's own heredoc
# expansion, a separate concern from Terraform's templatefile().
###############################################################
set -euxo pipefail

echo "[INFO] Install nginx"
apt-get update
apt-get install -y nginx curl

echo "[INFO] Discover this instance's current public IP"
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
PUBLIC_IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

echo "[INFO] Configure nginx reverse proxy -> ALB (${alb_dns_name})"
cat <<NGINX_EOF >/etc/nginx/sites-available/cluster
server {
  listen 80;
  server_name $PUBLIC_IP;

  location / {
    proxy_pass http://${alb_dns_name};
    proxy_http_version 1.1;

    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
  }
}
NGINX_EOF

rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/cluster /etc/nginx/sites-enabled/cluster

nginx -t
systemctl enable nginx
systemctl restart nginx
