HOST_IP="127.0.0.1"
HOST_USER="<candidate_lab_user>"
exec ssh \
  -o StrictHostKeyChecking=no \
  -o PasswordAuthentication=no \
  -o LogLevel=ERROR \
  -o UserKnownHostsFile=/dev/null \
  -i /home/openvscode-server/.ssh/id_ed25519 \
  ${HOST_USER}@${HOST_IP} || exit