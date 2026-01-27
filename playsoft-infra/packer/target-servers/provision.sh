#!/bin/bash
set -e

# --- Step 1: Create new user 
useradd -m -s /bin/bash instalab
echo "instalab:instalab" | chpasswd

# Give 'instalab' sudo privileges
usermod -aG sudo instalab
echo "instalab ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/instalab
chmod 440 /etc/sudoers.d/instalab

# --- Step 2: Install full KDE desktop and XRDP ---
apt update -y
DEBIAN_FRONTEND=noninteractive apt install -y kde-full xrdp dbus-x11

# --- Step 3: Allow RDP through firewall ---
ufw allow 3389/tcp

# --- Step 4: Enable and start XRDP ---
systemctl enable xrdp
systemctl restart xrdp

# --- Step 5: Set KDE as default session for 'instalab' ---
echo "startplasma-x11" > /home/instalab/.xsession
chmod 600 /home/instalab/.xsession
chown instalab:instalab /home/instalab/.xsession


