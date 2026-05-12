#!/bin/bash
set -x

# ─────────────────────────────────────────────
# Add svcuseran to docker group
# ─────────────────────────────────────────────
usermod -aG docker svcuseran

# ─────────────────────────────────────────────
# Write docker-compose.yml inline
# ─────────────────────────────────────────────
cat << 'COMPOSE' > /tmp/docker-compose.yml
version: '3'
services:
  control-node:
    image: docker.io/jilanigh/ansible-ubuntu-controller:v3
    container_name: control-node
    hostname: control-node
    depends_on:
      - web1
      - web2
    networks:
      - ansible-net
    environment:
      - ANSIBLE_HOST_KEY_CHECKING=False
    tty: true
    privileged: true

  web1:
    image: docker.io/jilanigh/ansible-ubuntu-client:v3
    container_name: web1
    hostname: web1
    networks:
      - ansible-net
    tty: true
    privileged: true

  web2:
    image: docker.io/jilanigh/ansible-ubuntu-client:v3
    container_name: web2
    hostname: web2
    networks:
      - ansible-net
    tty: true
    privileged: true

networks:
  ansible-net:
    driver: bridge
COMPOSE

chmod 644 /tmp/docker-compose.yml

# ─────────────────────────────────────────────
# Start all containers
# ─────────────────────────────────────────────
sudo su - svcuseran -c "cd /tmp && docker compose up -d"

sleep 5

# ─────────────────────────────────────────────
# Generate a fresh SSH key pair
# ─────────────────────────────────────────────
rm -f /tmp/id_rsa /tmp/id_rsa.pub
sudo su - svcuseran -c "ssh-keygen -t rsa -b 2048 -f /tmp/id_rsa -q -N ''"

# ─────────────────────────────────────────────
# Cleanup .ssh folders in containers
# ─────────────────────────────────────────────
sudo su - svcuseran -c "docker exec control-node rm -f /home/ansible_user/.ssh/*"
sudo su - svcuseran -c "docker exec web1 rm -f /home/ansible_user/.ssh/*"
sudo su - svcuseran -c "docker exec web2 rm -f /home/ansible_user/.ssh/*"

# ─────────────────────────────────────────────
# Distribute keys — Control Node
# ─────────────────────────────────────────────
sudo su - svcuseran -c "docker cp /tmp/id_rsa control-node:/home/ansible_user/.ssh/id_rsa"
sudo su - svcuseran -c "docker cp /tmp/id_rsa.pub control-node:/home/ansible_user/.ssh/id_rsa.pub"
sudo su - svcuseran -c "docker exec control-node chmod 600 /home/ansible_user/.ssh/id_rsa"
sudo su - svcuseran -c "docker exec control-node chmod 644 /home/ansible_user/.ssh/id_rsa.pub"
sudo su - svcuseran -c "docker exec control-node chown ansible_user:ansible_user /home/ansible_user/.ssh/id_rsa /home/ansible_user/.ssh/id_rsa.pub"

# ─────────────────────────────────────────────
# Distribute keys — Managed Nodes
# ─────────────────────────────────────────────
for node in web1 web2; do
  sudo su - svcuseran -c "docker cp /tmp/id_rsa.pub ${node}:/home/ansible_user/.ssh/authorized_keys"
  sudo su - svcuseran -c "docker exec ${node} chmod 600 /home/ansible_user/.ssh/authorized_keys"
  sudo su - svcuseran -c "docker exec ${node} chown ansible_user:ansible_user /home/ansible_user/.ssh/authorized_keys"
done

# ─────────────────────────────────────────────
# Write Ansible inventory on control node
# ─────────────────────────────────────────────
sudo su - svcuseran -c "docker exec control-node bash -c \"
echo '[webservers]' > /etc/ansible/hosts &&
echo 'web1' >> /etc/ansible/hosts &&
echo 'web2' >> /etc/ansible/hosts
\""

# ─────────────────────────────────────────────
# Update /etc/hosts on control node
# ─────────────────────────────────────────────
sudo su - svcuseran -c "docker exec control-node bash -c \"
getent hosts web1 | awk '{print \$1, \\\"web1\\\"}' | tail -n 1 | tee -a /etc/hosts &&
getent hosts web2 | awk '{print \$1, \\\"web2\\\"}' | tail -n 1 | tee -a /etc/hosts
\""

# ─────────────────────────────────────────────
# Setup auto-login to control-node for svcuseran
# ─────────────────────────────────────────────
grep -q "docker exec -it control-node bash" /home/svcuseran/.bash_profile || \
sudo su - svcuseran -c "cat << 'BASHEOF' >> /home/svcuseran/.bash_profile

# Drop into the Ansible control node automatically
docker exec -it control-node bash
if [ \$? -ne 0 ]; then
   echo \"Unable to connect to control-node. Logging out...\"
   exit
fi
exit
BASHEOF"

echo "Lab is ready! svcuseran will be redirected to control-node on login."
