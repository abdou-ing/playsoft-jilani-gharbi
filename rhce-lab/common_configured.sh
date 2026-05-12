
#!/bin/bash
set -x

# Define variables

cat <<EOF > /tmp/podman-compose.yml
version: '3'
services:
  control-node:
    image: docker.io/abdou777/ansible-ubuntu-controller:1.0
    container_name: control-node
    hostname: control-node
    depends_on:
      - web1
      - web2
    networks:
      - ansible-net
    environment:
      - ANSIBLE_HOST_KEY_CHECKING=false  # Enable host key checking
    command: >
      /bin/bash -c "
      getent hosts web1 | awk '{print \$1, \"web1\"}' | tail -n 1 | sudo tee -a /etc/hosts &&
      getent hosts web2 | awk '{print \$1, \"web2\"}' | tail -n 1 | sudo tee -a /etc/hosts &&
      getent hosts db1 | awk '{print \$1, \"db1\"}' | tail -n 1 | sudo tee -a /etc/hosts &&
      echo '[webservers]' > /etc/ansible/hosts &&
      echo 'web1' >> /etc/ansible/hosts &&
      echo 'web2' >> /etc/ansible/hosts &&
      sudo service ssh start &&
      sleep 3600"
    tty: true
    user: ansible_user
    privileged: true

  web1:
    image: docker.io/abdou777/ansible-ubuntu-client:1.0
    container_name: web1
    hostname: web1
    networks:
      - ansible-net
    command: >
      /bin/bash -c "
      sudo service ssh start &&
      sleep 3600"
    tty: true
    user: ansible_user
    privileged: true

  web2:
    image: docker.io/abdou777/ansible-ubuntu-client:1.0
    container_name: web2
    hostname: web2
    networks:
      - ansible-net
    command: >
      /bin/bash -c "
      sudo service ssh start &&
      sleep 3600"
    tty: true
    user: ansible_user
    privileged: true

networks:
  ansible-net:
    driver: bridge
EOF

# Adjust permissions to make the file accessible
chmod 644 "/tmp/podman-compose.yml"

# Execute podman-compose up -d using the created file
sudo su - student -c "cd /tmp/ && podman-compose up -d" >/dev/null 2>&1

# Generate key-pair
sudo rm -f /tmp/id_rsa /tmp/id_rsa.pub
sudo su - student -c "ssh-keygen -t rsa -b 2048 -f /tmp/id_rsa -q -N '' "

# Cleanup .ssh folder (need to update Dockerfile for controller and managed nodes)
echo "cleanup0" >> /tmp/output.log
sudo su - student -c "podman exec control-node rm -f /home/ansible_user/.ssh/*"
echo "cleanup1" >> /tmp/output.log
sudo su - student -c "podman exec web1 rm -f /home/ansible_user/.ssh/*" >/dev/null 2>&1
echo "cleanup2" >> /tmp/output.log
sudo su - student -c "podman exec web2 rm -f /home/ansible_user/.ssh/*" >/dev/null 2>&1
echo "cleanup3" >> /tmp/output.log

# Manage keys (controller)
echo "controller" >> /tmp/output.log
sudo su - student -c "podman cp /tmp/id_rsa control-node:/home/ansible_user/.ssh/id_rsa" >/dev/null 2>&1
#sudo su - student -c "podman exec -it control-node bash -c 'chmod 600 /home/ansible_user/.ssh/id_rsa'" >/dev/null 2>&1
sudo su - student -c "podman exec control-node chmod 600 /home/ansible_user/.ssh/id_rsa"
sudo su - student -c "podman cp /tmp/id_rsa.pub control-node:/home/ansible_user/.ssh/id_rsa.pub" >/dev/null 2>&1
sudo su - student -c "podman exec control-node bash chmod 644 /home/ansible_user/.ssh/id_rsa.pub" >/dev/null 2>&1
## Download the script from the S3 bucket
#aws s3 cp "$playbooks_path/$playbook_name" "/tmp"
#sudo su - student -c "podman cp /tmp/$playbook_name control-node:/home/ansible_user/playbooks/"


# Manage keys (web1)
echo "web1" >> /tmp/output.log
sudo su - student -c "podman cp /tmp/id_rsa.pub web1:/home/ansible_user/.ssh/authorized_keys" >/dev/null 2>&1
sudo su - student -c "podman exec web1 chmod 600 /home/ansible_user/.ssh/authorized_keys" >/dev/null 2>&1
sudo su - student -c "podman exec web1 chown ansible_user:ansible_user /home/ansible_user/.ssh/authorized_keys" >/dev/null 2>&1

# Manage keys (web2)
sudo su - student -c "podman cp /tmp/id_rsa.pub web2:/home/ansible_user/.ssh/authorized_keys" >/dev/null 2>&1
sudo su - student -c "podman exec web2 bash chmod 600 /home/ansible_user/.ssh/authorized_keys" >/dev/null 2>&1
sudo su - student -c "podman exec web2 bash chown ansible_user:ansible_user /home/ansible_user/.ssh/authorized_keys" >/dev/null 2>&1

## Cleanup the temporary directory
#rm -rf "/tmp"

sudo su - student -c "cat << 'EOF' >> /home/student/.bashrc

# Automatically log into container 'control-node' when user logs in
podman exec -it control-node bash
# Check if the previous command failed (exit code not 0)
if [ \$? -ne 0 ]; then
   echo \"Unable to connect. Logging out...\"
   exit
fi
# If the user exits the container, terminate the parent shell as well
exit
EOF"