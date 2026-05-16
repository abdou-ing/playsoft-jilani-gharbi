#!/bin/bash
set -x

# Create podman-compose file in permanent location
mkdir -p /opt/ansible-lab

cat <<EOF > /opt/ansible-lab/podman-compose.yml
version: '3'
services:
  control-node:
    image: localhost/abdou777/ansible-ubuntu-controller:1.0
    container_name: control-node
    hostname: control-node
    depends_on:
      - web1
      - web2
    networks:
      - ansible-net
    environment:
      - ANSIBLE_HOST_KEY_CHECKING=false
    command: >
      /bin/bash -c "
      sudo service ssh start &&
      sleep infinity"
    tty: true
    user: ansible_user
    privileged: true
    restart: unless-stopped

  web1:
    image: localhost/abdou777/ansible-ubuntu-client:1.0
    container_name: web1
    hostname: web1
    networks:
      - ansible-net
    command: >
      /bin/bash -c "
      sudo service ssh start &&
      sleep infinity"
    tty: true
    user: ansible_user
    privileged: true
    restart: unless-stopped

  web2:
    image: localhost/abdou777/ansible-ubuntu-client:1.0
    container_name: web2
    hostname: web2
    networks:
      - ansible-net
    command: >
      /bin/bash -c "
      sudo service ssh start &&
      sleep infinity"
    tty: true
    user: ansible_user
    privileged: true
    restart: unless-stopped

networks:
  ansible-net:
    driver: bridge
EOF

# Adjust permissions
chmod 644 /opt/ansible-lab/podman-compose.yml
chown student:student /opt/ansible-lab/podman-compose.yml

# Create systemd service
cat > /etc/systemd/system/ansible-lab.service << 'EOF'
[Unit]
Description=Ansible Lab Containers
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=student
Environment=XDG_RUNTIME_DIR=/run/user/1000
ExecStart=/usr/bin/podman-compose -f /opt/ansible-lab/podman-compose.yml up -d
ExecStop=/usr/bin/podman-compose -f /opt/ansible-lab/podman-compose.yml down
TimeoutStartSec=60

[Install]
WantedBy=multi-user.target
EOF

# Enable linger and service
loginctl enable-linger student
systemctl daemon-reload
systemctl enable ansible-lab.service

# Start containers
sudo -u student podman-compose -f /opt/ansible-lab/podman-compose.yml up -d

# Wait for containers to be fully up
sleep 5

# Set passwords for web1 and web2 as root
sudo -u student podman exec --user root web1 bash -c "echo 'ansible_user:Labby123' | chpasswd"
sudo -u student podman exec --user root web2 bash -c "echo 'ansible_user:Labby123' | chpasswd"

# Wait for IPs to be assigned
sleep 3

# Get IPs
WEB1_IP=$(sudo -u student podman inspect web1 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
WEB2_IP=$(sudo -u student podman inspect web2 --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')
CONTROL_IP=$(sudo -u student podman inspect control-node --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

# Generate IP file inside control-node /tmp
sudo -u student podman exec control-node bash -c "cat > /tmp/lab_info.txt << EOF
======================================
        LAB SETUP COMPLETE
======================================

  CONTAINER         IP ADDRESS
  ───────────────────────────────────
  control-node  →   $CONTROL_IP
  web1          →   $WEB1_IP
  web2          →   $WEB2_IP

  SSH credentials for web1 and web2:
  user: ansible_user
  pass: Labby123

======================================
EOF"

# Add auto-login to .bashrc
sudo tee -a /home/student/.bashrc > /dev/null << 'BASHRC'

# Automatically log into container 'control-node' when user logs in
if [ -z "$IN_CONTAINER" ]; then
    export IN_CONTAINER=1
    podman exec -it control-node bash
    if [ $? -ne 0 ]; then
        echo "Unable to connect. Logging out..."
    fi
    exit
fi
BASHRC
