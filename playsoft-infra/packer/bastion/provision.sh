# #!/bin/bash
# set -e

# # 1. Update and install Nginx
# echo "[INFO] Updating packages and installing Nginx..."
# apt update -y
# apt install -y nginx

# # 2. Check Nginx status
# systemctl enable --now nginx
# systemctl status nginx --no-pager

# # 3. Configure Nginx reverse proxy
# GUAC_ROUTE="guacamole"           # <-- your route
# PRIVATE_SERVER="10.20.0.3"    # <-- private IP of bastion/Kind node

# NGINX_CONF="/etc/nginx/sites-available/guacamole"

# echo "[INFO] Writing Nginx configuration..."
# cat > $NGINX_CONF <<EOF
# server {
#     listen 80 default_server;
#     server_name _;

#     # redirect root to /$GUAC_ROUTE/
#     location = / {
#         return 301 /$GUAC_ROUTE/;
#     }

#     # proxy all /$GUAC_ROUTE/ requests
#     location /$GUAC_ROUTE/ {
#         proxy_pass http://$PRIVATE_SERVER:8080/guacamole/;
#         proxy_http_version 1.1;
#         proxy_set_header Upgrade \$http_upgrade;
#         proxy_set_header Connection "upgrade";
#         proxy_set_header Host \$host;
#         proxy_set_header X-Forwarded-For \$remote_addr;
#         proxy_set_header X-Forwarded-Proto \$scheme;
#     }
# }
# EOF
# # Disable default site
# sudo rm /etc/nginx/sites-enabled/default
# # 4. Enable site
# ln -sf /etc/nginx/sites-available/guacamole /etc/nginx/sites-enabled/

# # 5. Test configuration and reload
# nginx -t
# systemctl reload nginx

# # 6. Cleanup duplicate default servers if any
# DUPLICATES=$(grep -R "default_server" /etc/nginx/sites-enabled/)
# if [ ! -z "$DUPLICATES" ]; then
#     echo "[INFO] Removing default site to avoid conflicts..."
#     rm -f /etc/nginx/sites-enabled/default
#     nginx -t
#     systemctl reload nginx
# fi

# echo "[INFO] Reverse proxy setup complete!"
