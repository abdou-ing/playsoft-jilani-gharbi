#!/bin/bash
set -euxo pipefail

sudo apt update
sudo apt install -y xfce4 xfce4-goodies

VNC_DIR="$HOME/.vnc"
XSTARTUP="$VNC_DIR/xstartup"

mkdir -p "$VNC_DIR"

cat <<'EOF' > "$XSTARTUP"
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
vncconfig -iconic &
startxfce4 &
EOF

chmod +x "$XSTARTUP"