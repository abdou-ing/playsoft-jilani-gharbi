#!/bin/bash
#==============================================================================
# Cloud-Init Setup Script for AlmaLinux 9 Template
#==============================================================================
# Purpose: Configure Cloud-Init for Proxmox templates
# Author:  Joshua Kunz
# Date:    April 20, 2025
# Version: 1.0
#
# This script:
# - Configures Cloud-Init for use with Proxmox
# - Sets up appropriate default Cloud-Init settings
# - Ensures Cloud-Init services are enabled
#==============================================================================

# Exit on error
set -e

# Log function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/cloud-init-setup.log
}

log "Starting Cloud-Init setup for Proxmox template"

#------------------------------------------------------------------------------
# Install required packages if not already installed
#------------------------------------------------------------------------------
log "Ensuring required packages are installed"
dnf install -y cloud-init qemu-guest-agent rsync NetworkManager

#------------------------------------------------------------------------------
# Configure Cloud-Init defaults
#------------------------------------------------------------------------------
log "Configuring Cloud-Init defaults"

# Create Proxmox-specific Cloud-Init config
cat > /etc/cloud/cloud.cfg.d/99-pve.cfg <<EOF
datasource_list: [NoCloud, ConfigDrive]
datasource:
  NoCloud:
    fs_label: cidata
  ConfigDrive:
    fs_label: cidata

# Set maximum wait time for metadata services
max_wait: 120

# Preserve instance hostname
preserve_hostname: false

# Set default user
system_info:
  default_user:
    name: cloud-user
    lock_passwd: false
    gecos: Cloud User
    groups: [wheel, adm, systemd-journal]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
EOF

#------------------------------------------------------------------------------
# Ensure Cloud-Init services are enabled
#------------------------------------------------------------------------------
log "Enabling Cloud-Init services"
systemctl enable cloud-init
systemctl enable cloud-config
systemctl enable cloud-final
systemctl enable cloud-init-local

#------------------------------------------------------------------------------
# Configure Network Manager for Cloud-Init compatibility
#------------------------------------------------------------------------------
log "Configuring Network Manager for Cloud-Init"
cat > /etc/NetworkManager/conf.d/99-cloud-init.conf <<EOF
[main]
plugins=ifcfg-rh
EOF

# Ensure NetworkManager is enabled
systemctl enable NetworkManager

log "Cloud-Init setup completed successfully"
exit 0