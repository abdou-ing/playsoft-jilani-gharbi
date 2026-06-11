#!/bin/bash
#==============================================================================
# VM Template Cleanup Script
#==============================================================================
# Purpose: Clean up the VM before converting to a template
# Author:  Joshua Kunz
# Date:    April 20, 2025
# Version: 1.1 - Fixed dbus directory creation issue
#
# This script:
# - Removes unique identifiers and logs
# - Cleans up package cache
# - Resets Cloud-Init
# - Ensures proper templating for Proxmox
#==============================================================================

# Exit on error (but allow some commands to fail gracefully)
set -e

# Log function
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /root/template-cleanup.log
}

log "Starting template cleanup process"

#------------------------------------------------------------------------------
# Remove SSH host keys
#------------------------------------------------------------------------------
log "Removing SSH host keys"
rm -f /etc/ssh/ssh_host_*
# Add a Cloud-Init job to regenerate SSH host keys on first boot
cat > /etc/cloud/cloud.cfg.d/20-regenerate-ssh-host-keys.cfg <<EOF
# Regenerate SSH host keys on first boot
ssh_deletekeys: True
ssh_genkeytypes: ['rsa', 'ecdsa', 'ed25519']
EOF

#------------------------------------------------------------------------------
# Clean machine-specific identifiers
#------------------------------------------------------------------------------
log "Cleaning machine-specific identifiers"
# Remove machine ID - will be regenerated on first boot
truncate -s 0 /etc/machine-id

# Handle dbus machine-id with proper error checking
if [ -f /var/lib/dbus/machine-id ]; then
    rm -f /var/lib/dbus/machine-id
fi

# Ensure dbus directory exists before creating symlink
mkdir -p /var/lib/dbus
if [ ! -L /var/lib/dbus/machine-id ]; then
    ln -sf /etc/machine-id /var/lib/dbus/machine-id
fi

# Remove persistent network rules if they exist
rm -f /etc/udev/rules.d/70-persistent-net.rules
rm -f /etc/udev/rules.d/70-persistent-cd.rules

#------------------------------------------------------------------------------
# Clean package cache and logs
#------------------------------------------------------------------------------
log "Cleaning package cache and logs"
# Clean DNF cache
dnf clean all
rm -rf /var/cache/dnf

# Remove temporary files
rm -rf /tmp/* /var/tmp/*

# Clean log files but handle cases where directories might not exist
if [ -d /var/log ]; then
    find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true
fi

# Clean specific log files if they exist
[ -d /var/log/audit ] && rm -f /var/log/audit/* || true
[ -f /root/.bash_history ] && rm -f /root/.bash_history || true

#------------------------------------------------------------------------------
# Reset Cloud-Init state
#------------------------------------------------------------------------------
log "Resetting Cloud-Init state"
# Remove cloud-init state
cloud-init clean --logs || true

# Remove cloud-init instance data if it exists
[ -d /var/lib/cloud/instances ] && rm -rf /var/lib/cloud/instances/* || true

# Remove installer-related files
rm -f /root/anaconda-ks.cfg || true
rm -f /root/original-ks.cfg || true
rm -f /root/install.log || true
rm -f /root/install.log.syslog || true

#------------------------------------------------------------------------------
# Additional cleanup for template preparation
#------------------------------------------------------------------------------
log "Performing additional template cleanup"

# Clear systemd machine ID to ensure it gets regenerated
systemd-machine-id-setup --print > /dev/null 2>&1 || true

# Clear any DHCP leases
rm -f /var/lib/dhclient/* || true
rm -f /var/lib/NetworkManager/* || true

# Clear any cached SSH known hosts
rm -f /root/.ssh/known_hosts || true
rm -f /home/*/.ssh/known_hosts || true

#------------------------------------------------------------------------------
# Remove this script before finishing
#------------------------------------------------------------------------------
log "Template cleanup completed successfully"
# Remove the copied scripts
rm -f /tmp/setup-cloud-init.sh || true
rm -f /tmp/cleanup.sh || true

# Sync filesystem to ensure all changes are written
sync

log "All cleanup operations completed"
exit 0