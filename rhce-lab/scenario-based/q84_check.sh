#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/ssh_hardening.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_lineinfile"]="The playbook does not use lineinfile. Use ansible.builtin.lineinfile to modify /etc/ssh/sshd_config."
  ["no_service"]="The playbook does not restart the SSH service. Add a service task: name: ssh, state: restarted."
  ["wrong_root"]="PermitRootLogin is not set to 'no' on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["wrong_passwd"]="PasswordAuthentication is not set to 'no' on web1. Ensure your lineinfile task sets 'PasswordAuthentication no'."
  ["wrong_alive"]="ClientAliveInterval is not set to 300 on web1. Ensure your lineinfile task sets 'ClientAliveInterval 300'."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_lineinfile"]="Le playbook n'utilise pas lineinfile. Utilisez ansible.builtin.lineinfile pour modifier /etc/ssh/sshd_config."
  ["no_service"]="Le playbook ne redémarre pas le service SSH. Ajoutez une tâche service : name: ssh, state: restarted."
  ["wrong_root"]="PermitRootLogin n'est pas défini à 'no' sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["wrong_passwd"]="PasswordAuthentication n'est pas défini à 'no' sur web1. Assurez-vous que votre tâche lineinfile définit 'PasswordAuthentication no'."
  ["wrong_alive"]="ClientAliveInterval n'est pas défini à 300 sur web1. Assurez-vous que votre tâche lineinfile définit 'ClientAliveInterval 300'."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "lineinfile" "$pb_path"; then
  echo "$(get_message no_lineinfile)"; exit 0
fi

if ! grep -q "restarted" "$pb_path"; then
  echo "$(get_message no_service)"; exit 0
fi

sshd_output=$(ansible web1 -i "$inventory" -m command -a "sshd -T" --become 2>/dev/null)

if ! echo "$sshd_output" | grep -qi "permitrootlogin no"; then
  echo "$(get_message wrong_root)"; exit 0
fi

if ! echo "$sshd_output" | grep -qi "passwordauthentication no"; then
  echo "$(get_message wrong_passwd)"; exit 0
fi

if ! echo "$sshd_output" | grep -qi "clientaliveinterval 300"; then
  echo "$(get_message wrong_alive)"; exit 0
fi

echo '{"result": "0"}'
