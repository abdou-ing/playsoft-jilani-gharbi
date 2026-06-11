#!/bin/bash

#set -eoux 
set -x 

# Default values (optional)
WAZUH_GROUP='wazuh'

# Validate DB_POSTGRES_PASSWORD

# Validate CANDIDATE_LAB_USER
if [ -z "${CANDIDATE_LAB_USER}" ]; then
  echo "ERROR: CANDIDATE_LAB_USER is not set or is empty. Please specify a valid candidate lab username." >&2
  exit 1
fi

# Validate CANDIDATE_LAB_USER_PASSWORD
if [ -z "${CANDIDATE_LAB_USER_PASSWORD}" ]; then
  echo "ERROR: CANDIDATE_LAB_USER_PASSWORD is not set or is empty. Please specify a valid password for the candidate lab user." >&2
  exit 1
fi

# Validate CUSTOM_USER_GROUPS
if [ -z "${CUSTOM_USER_GROUPS}" ]; then
  echo "ERROR: CUSTOM_USER_GROUPS is not set or is empty. Please specify valid user groups." >&2
  exit 1
fi

# Validate MANAGEMENT_LAB_USER
if [ -z "${MANAGEMENT_LAB_USER}" ]; then
  echo "ERROR: MANAGEMENT_LAB_USER is not set or is empty. Please specify a valid lab management username." >&2
  exit 1
fi

# If all checks pass
echo "All required environment variables are properly set."

## Parse named arguments
#while [[ $# -gt 0 ]]; do
#  case "$1" in
#    --MANAGEMENT_LAB_USER=*)
#      MANAGEMENT_LAB_USER="${1#*=}"  # Extracts value after "="
#      shift           # Move to next argument
#      ;;
#    --CANDIDATE_LAB_USER=*)
#      CANDIDATE_LAB_USER="${1#*=}"   # Extracts value after "="
#      shift           # Move to next argument
#      ;;
#    --CANDIDATE_LAB_USER_password=*)
#      CANDIDATE_LAB_USER_password="${1#*=}"   # Extracts value after "="
#      shift           # Move to next argument
#      ;;
#    --custom_user_groups=*)
#      custom_user_groups="${1#*=}"   # Extracts value after "="
#      shift           # Move to next argument
#      ;;
#    *)
#      echo "Unknown argument: $1"
#      exit 1
#      ;;
#  esac
#done
#
## Check if arguments are provided
#if [ -z "${MANAGEMENT_LAB_USER}" ]  || [ -z "${CANDIDATE_LAB_USER}" ]  || [ -z "${CANDIDATE_LAB_USER_PASSWORD}" ]  || [ -z "${CUSTOM_USER_GROUPS}" ] ; then
#  echo "Usage: $0 --MANAGEMENT_LAB_USER=<name> --CANDIDATE_LAB_USER=<user_name> --CANDIDATE_LAB_USER_password=<password> --custom_user_groups=<group_name>"
#  echo "Example: $0 --MANAGEMENT_LAB_USER=toto --CANDIDATE_LAB_USER=student --CANDIDATE_LAB_USER_password=Mypass123!! --custom_user_groups=group_dev"
#  exit 1
#fi
#

# update the system and install required packages
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf remove podman buildah -y
yum makecache
yum install epel-release
yum update -y
yum install make automake gcc autoconf libtool openssl-devel pkg-config jq audit audit-libs inotify-tools docker-ce docker-ce-cli containerd.io -y

systemctl start docker.service
systemctl enable docker.service
#yum install glibc-langpack-{fr,en,de,es,it} -y

dnf groupinstall -y "Server with GUI"
systemctl enable gdm
systemctl set-default graphical.target

# Compile/configure yara
#sudo yum makecache
#sudo yum install epel-release
#sudo yum update
#sudo yum install -y make automake gcc autoconf libtool openssl-devel pkg-config jq
####curl -LO https://github.com/VirusTotal/yara/archive/v4.2.3.tar.gz
####tar -xvzf v4.2.3.tar.gz -C /usr/local/bin/ && rm -f v4.2.3.tar.gz
####cd /usr/local/bin/yara-4.2.3/
####sudo ./bootstrap.sh && sudo ./configure && sudo make && sudo make install && sudo make check
####
####if [ -f /usr/local/lib/libyara.so.9 ]; then
####  echo \"/usr/local/lib\" >> /etc/ld.so.conf
####  ldconfig
####fi
#####yara --help
####
####mkdir -p /opt/yara/rules
####curl 'https://valhalla.nextron-systems.com/api/v1/get' \
####-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
####-H 'Accept-Language: en-US,en;q=0.5' \
####--compressed \
####-H 'Referer: https://valhalla.nextron-systems.com/' \
####-H 'Content-Type: application/x-www-form-urlencoded' \
####-H 'DNT: 1' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' \
####--data 'demo=demo&apikey=1111111111111111111111111111111111111111111111111111111111111111&format=text' \
####-o /opt/yara/rules/yara_rules.yar

# Configure user to be used from the candidate
useradd -m -s /bin/bash  ${CANDIDATE_LAB_USER}
echo ${CANDIDATE_LAB_USER_PASSWORD} | sudo passwd --stdin ${CANDIDATE_LAB_USER}
touch /home/${CANDIDATE_LAB_USER}/.hushlogin
chown ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} /home/${CANDIDATE_LAB_USER}/.hushlogin
mkdir -p /home/${CANDIDATE_LAB_USER}/.ssh
chmod 700 /home/${CANDIDATE_LAB_USER}/.ssh/
chown ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} /home/${CANDIDATE_LAB_USER}/.ssh/
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfuBDZsQl5DuPC7RTrPf13c6lvICqKbmVlYJVheI4za' | tee -a /home/${CANDIDATE_LAB_USER}/.ssh/authorized_keys

# Configure user for management
useradd ${MANAGEMENT_LAB_USER}
echo "${MANAGEMENT_LAB_USER} ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers.d/${MANAGEMENT_LAB_USER}
mkdir -p /home/${MANAGEMENT_LAB_USER}/.ssh
chmod 700 /home/${MANAGEMENT_LAB_USER}/.ssh/
chown ${MANAGEMENT_LAB_USER}:${MANAGEMENT_LAB_USER} /home/${MANAGEMENT_LAB_USER}/.ssh/
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHfuBDZsQl5DuPC7RTrPf13c6lvICqKbmVlYJVheI4za' | tee -a /home/${MANAGEMENT_LAB_USER}/.ssh/authorized_keys
usermod -aG docker ${MANAGEMENT_LAB_USER}
####loginctl enable-linger $(id -u $management_lab_user)

# Change ssh config
sed -i 's|PasswordAuthentication no|PasswordAuthentication yes|g'  /etc/ssh/sshd_config
sleep 1
systemctl restart sshd

# Set hostname and cloud_init
hostnamectl set-hostname lab-server
echo 'ssh_pwauth:   true' | tee /etc/cloud/cloud.cfg.d/00_defaults.cfg
echo 'preserve_hostname: true' | tee -a /etc/cloud/cloud.cfg.d/00_defaults.cfg



# Manage motivational messages
mv /tmp/motivation_messages*.txt /tmp/random_motivation.sh /opt
chmod 505 /opt/random_motivation.sh
#echo 'source /opt/random_motivation.sh'  | tee -a /etc/profile
#echo 'source /opt/random_motivation.sh'  | tee -a /home/${CANDIDATE_LAB_USER}/.bashrc
echo 'export PS1="\[\e[1;1;38;5;51m\]\u\[\e[1;1;38;5;231m\]@\[\e[1;1;38;5;220m\]\h \[\e[38;5;46m\]\w\[\e[0m\]\$ "'  | tee -a /home/${CANDIDATE_LAB_USER}/.bashrc


echo "en" > /opt/user_lang.txt
chmod 664 /opt/user_lang.txt
chown root:${MANAGEMENT_LAB_USER} /opt/user_lang.txt

# Make the function available to all users
mv /tmp/is_container /usr/local/bin/is_container
sudo chmod +x /usr/local/bin/is_container



# Configure background 
cp /tmp/instalab_redhat.png /usr/share/backgrounds/instalab_redhat.png
cp /tmp/instalab_redhat.png /opt
chown root:root /usr/share/backgrounds/instalab_redhat.png

VERSION=$(grep -E "^VERSION_ID=" /etc/os-release | cut -d'"' -f2 | cut -d'.' -f1)
    
case "$VERSION" in
    9)
        echo "AlmaLinux 9 detected"
        sed -i 's|/usr/share/backgrounds/[^<]*|/usr/share/backgrounds/instalab_redhat.png|g' /usr/share/backgrounds/Alma-mountains-white.xml
        #exit 9
        ;;
    10)
        echo "AlmaLinux 10 detected"
        mkdir -p /etc/dconf/db/local.d
        cat > /etc/dconf/db/local.d/02-background <<'EOF'
[org/gnome/desktop/background]
picture-uri='file:///usr/share/backgrounds/instalab_redhat.png'
picture-uri-dark='file:///usr/share/backgrounds/instalab_redhat.png'
EOF
        #exit 10
        ;;
    *)
        echo "AlmaLinux $VERSION detected (not 9 or 10)"
        exit 1
        ;;
esac
# (Alma 10+)
#gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/instalab_redhat.png'
#gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/instalab_redhat.png'
#(Alma 9)
#sed -i 's|/usr/share/backgrounds/[^<]*|/usr/share/backgrounds/instalab_redhat.png|g' /usr/share/backgrounds/Alma-mountains-white.xml


# remove welcome to almalinux message on first login For all users (system-wide)
mkdir -p /etc/dconf/db/local.d /etc/dconf/profile

# Tell GNOME to consult the system 'local' database for defaults/locks
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
EOF

tee /etc/dconf/db/local.d/01-no-welcome <<EOF
[org/gnome/shell]
welcome-dialog-last-shown-version='99.0'
EOF
dconf update




# Force us keyboard to avoid guacamole double mapping of keys
mkdir -p /etc/dconf/db/local.d
cat >> /etc/dconf/db/local.d/01-no-welcome <<'EOF'

[org/gnome/desktop/input-sources]
sources=[('xkb', 'us')]
EOF


# =============================================================================
# Workspace ownership enforcer
# Forces student:student ownership on any file created under terraform/
# regardless of which process created it (VS Code, terminal, upload, etc.)
# =============================================================================
yum install -y inotify-tools

cp /tmp/workspace_chown.sh /usr/local/bin/workspace_chown.sh
sed -i "s/<candidate_lab_user>/${CANDIDATE_LAB_USER}/g" /usr/local/bin/workspace_chown.sh
chmod +x /usr/local/bin/workspace_chown.sh

cp /tmp/workspace-chown.service /etc/systemd/system/workspace-chown.service
sed -i "s/<candidate_lab_user>/${CANDIDATE_LAB_USER}/g" /etc/systemd/system/workspace-chown.service
chmod +x /etc/systemd/system/workspace-chown.service

systemctl daemon-reload
systemctl enable workspace-chown

##### Configure podman
####systemctl start podman 
####systemctl enable podman
####echo 'unqualified-search-registries = ["docker.io"]' | tee -a /etc/containers/registries.conf

# =============================================================================
# OpenVSCode Server Setup
# Browser IDE on port 3000. Terminal auto-SSHes into the host as
# $CANDIDATE_LAB_USER (the "student" user).
# =============================================================================

# --- Replace your current VSCODE vars ---
VSCODE_CODE_DIR="/home/${CANDIDATE_LAB_USER}/workspace"   # dedicated dir, not the whole home
VSCODE_SSH_DIR="/home/${MANAGEMENT_LAB_USER}/ssh_keys"
VSCODE_CONTAINER_NAME="vscode_${CANDIDATE_LAB_USER}"

# --- Step 1: Create directory structure ---
mkdir  "${VSCODE_CODE_DIR}"
mkdir  "${VSCODE_SSH_DIR}"

setfacl -m u:${CANDIDATE_LAB_USER}:x "/home/${MANAGEMENT_LAB_USER}"

chown ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} "${VSCODE_CODE_DIR}"
chmod 755 "${VSCODE_CODE_DIR}"

setfacl -m u:1000:rwx "${VSCODE_CODE_DIR}"
setfacl -d -m u:1000:rwx "${VSCODE_CODE_DIR}"
setfacl -d -m u:${CANDIDATE_LAB_USER}:rwx "${VSCODE_CODE_DIR}"  
setfacl -d -m g::rwx "${VSCODE_CODE_DIR}"                       
setfacl -d -m o::r "${VSCODE_CODE_DIR}"                         

# Copy terraform into workspace, owned by student
####cp -r /home/${CANDIDATE_LAB_USER}/terraform "${VSCODE_CODE_DIR}/terraform"
####chown -R ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} "${VSCODE_CODE_DIR}/terraform"
####setfacl -R -m u:1000:rwx "${VSCODE_CODE_DIR}/terraform"
####setfacl -R -d -m u:1000:rwx "${VSCODE_CODE_DIR}/terraform"
mkdir -p ${VSCODE_CODE_DIR}/code
chown -R ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} "${VSCODE_CODE_DIR}/code"
setfacl -R -m u:1000:rwx "${VSCODE_CODE_DIR}/code"
setfacl -R -d -m u:1000:rwx "${VSCODE_CODE_DIR}/code"


# --- Step 2 & 3: SSH keygen + authorize (unchanged) ---
ssh-keygen -t ed25519 -f "${VSCODE_SSH_DIR}/id_ed25519" -N ""
cat "${VSCODE_SSH_DIR}/id_ed25519.pub" >> /home/${CANDIDATE_LAB_USER}/.ssh/authorized_keys

# Fix .ssh ownership — CANDIDATE_LAB_USER must own this, not uid 1000
chown ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} /home/${CANDIDATE_LAB_USER}/.ssh
chown ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} /home/${CANDIDATE_LAB_USER}/.ssh/authorized_keys
chmod 700 /home/${CANDIDATE_LAB_USER}/.ssh
chmod 600 /home/${CANDIDATE_LAB_USER}/.ssh/authorized_keys

# --- Step 4: SSH key ownership for container ---
chown -R 1000:1000 "${VSCODE_SSH_DIR}/"
chmod 700 "${VSCODE_SSH_DIR}/"
chmod 600 "${VSCODE_SSH_DIR}/id_ed25519"

# --- Step 5: VS Code settings inside workspace dir ---
mkdir -p "${VSCODE_CODE_DIR}/.openvscode-server/data/Machine"
mkdir -p "${VSCODE_CODE_DIR}/.openvscode-server/data/logs"
mkdir -p "${VSCODE_CODE_DIR}/.openvscode-server/extensions"
# chmod 777: rootless podman remaps uid 1000 inside container to a different host uid,
# so ACLs/chown targeting uid 1000 are insufficient — any mapped uid must be able to write
chmod -R 777 "${VSCODE_CODE_DIR}/.openvscode-server"

cp /tmp/vscode_settings.json "${VSCODE_CODE_DIR}/.openvscode-server/data/Machine/settings.json"

# --- Step 6: .bashrc auto-SSH (written into workspace dir) ---
cp /tmp/.bashrc "${VSCODE_CODE_DIR}/.bashrc"
sed -i "s/<candidate_lab_user>/${CANDIDATE_LAB_USER}/g" "${VSCODE_CODE_DIR}/.bashrc"
chown ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} "${VSCODE_CODE_DIR}/.bashrc"
setfacl -m u:1000:rwx "${VSCODE_CODE_DIR}/.bashrc"

####mkdir -p "/home/${CANDIDATE_LAB_USER}/.config/containers"
####cat > "/home/${CANDIDATE_LAB_USER}/.config/containers/storage.conf" <<EOF
####[storage]
####driver = "vfs"
####EOF
####cat > "/home/${CANDIDATE_LAB_USER}/.config/containers/containers.conf" <<EOF
####[engine]
####cgroup_manager = "cgroupfs"
####EOF
####chown -R "${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER}" "/home/${CANDIDATE_LAB_USER}/.config"

####su - "${CANDIDATE_LAB_USER}" -c "podman --cgroup-manager=cgroupfs system reset --force"
####su - "${CANDIDATE_LAB_USER}" -c "podman --cgroup-manager=cgroupfs build -f /tmp/docker_images/Dockerfile_openvscode_server -t playsoft-vscode:1.0 --no-cache /tmp/docker_images"
docker build -f /tmp/docker_images/Dockerfile_openvscode_server -t playsoft-vscode:1.0 --no-cache /tmp/docker_images
# --- Step 9: ACL-based dual ownership ---
# student owns everything — terminal (vim) can write
chown -R ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} "${VSCODE_CODE_DIR}"

# ACL grants uid 1000 (container/VS Code) full access without changing owner
setfacl -R -m u:1000:rwx "${VSCODE_CODE_DIR}"

# Default ACL: files created by either side are accessible by both
setfacl -R -d -m u:${CANDIDATE_LAB_USER}:rwx "${VSCODE_CODE_DIR}"
setfacl -R -d -m u:1000:rwx "${VSCODE_CODE_DIR}"

chown 1000:1000 "${VSCODE_CODE_DIR}/.bashrc"

# Re-enforce student SSH ownership last — never touch this after this point
chown -R ${CANDIDATE_LAB_USER}:${CANDIDATE_LAB_USER} /home/${CANDIDATE_LAB_USER}/.ssh
chmod 700 /home/${CANDIDATE_LAB_USER}/.ssh
chmod 600 /home/${CANDIDATE_LAB_USER}/.ssh/authorized_keys

systemctl start workspace-chown 



# Enable services
systemctl enable auditd
systemctl start auditd

## Configure wazuh agent "temporary"
#wget -O /tmp/wazuh-agent-4.11.1-1.x86_64.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-4.11.1-1.x86_64.rpm
#WAZUH_MANAGER='IP_WAZUH_SERVER' WAZUH_AGENT_NAME='LAB_NAME' rpm -ihv /tmp/wazuh-agent-4.11.1-1.x86_64.rpm
#
#chmod 750 /tmp/wazuh_files/*
#chown root:${WAZUH_GROUP} /tmp/wazuh_files/*
#mv /tmp/wazuh_files/* /var/ossec/active-response/bin/



sudo su - student -c "localectl set-locale LANG=it_IT.UTF-8"
sudo su - student -c "export LANG=it_IT.UTF-8"
sudo su - student -c "export LC_ALL=it_IT.UTF-8"

# Remove build-time connection profiles
nmcli con delete $(nmcli -t -f NAME con show) 2>/dev/null || true

# Create generic profiles that bind to interface NAME, not MAC
nmcli con add type ethernet ifname eth0 con-name eth0 ipv4.method auto connection.autoconnect yes
#nmcli con add type ethernet ifname eth1 con-name eth1 ipv4.method auto connection.autoconnect yes

# Ensure machine-id is reset for unique DHCP leases per clone
truncate -s 0 /etc/machine-id