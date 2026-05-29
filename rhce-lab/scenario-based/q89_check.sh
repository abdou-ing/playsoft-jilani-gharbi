#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/ip_forwarding.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_lineinfile"]="The playbook does not use lineinfile. Use ansible.builtin.lineinfile with create: yes to create /etc/sysctl.d/99-forwarding.conf."
  ["no_sysctl_file"]="/etc/sysctl.d/99-forwarding.conf does not exist on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["wrong_value"]="net.ipv4.ip_forward is not set to 1 on web1. Ensure your sysctl config contains 'net.ipv4.ip_forward = 1' and sysctl -p was applied."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_lineinfile"]="Le playbook n'utilise pas lineinfile. Utilisez ansible.builtin.lineinfile avec create: yes pour créer /etc/sysctl.d/99-forwarding.conf."
  ["no_sysctl_file"]="/etc/sysctl.d/99-forwarding.conf n'existe pas sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["wrong_value"]="net.ipv4.ip_forward n'est pas défini à 1 sur web1. Assurez-vous que votre config sysctl contient 'net.ipv4.ip_forward = 1' et que sysctl -p a été appliqué."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "lineinfile" "$pb_path"; then
  echo "$(get_message no_lineinfile)"; exit 0
fi

stat_result=$(ansible web1 -i "$inventory" -m stat \
  -a "path=/etc/sysctl.d/99-forwarding.conf" --become 2>/dev/null)
if ! echo "$stat_result" | grep -q '"exists": true'; then
  echo "$(get_message no_sysctl_file)"; exit 0
fi

sysctl_result=$(ansible web1 -i "$inventory" -m command \
  -a "sysctl net.ipv4.ip_forward" --become 2>/dev/null)
if ! echo "$sysctl_result" | grep -q "net.ipv4.ip_forward = 1"; then
  echo "$(get_message wrong_value)"; exit 0
fi

echo '{"result": "0"}'
