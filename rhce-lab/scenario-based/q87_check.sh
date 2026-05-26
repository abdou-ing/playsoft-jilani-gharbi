#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/hosts_entries.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_lineinfile"]="The playbook does not use lineinfile. Use ansible.builtin.lineinfile with path: /etc/hosts and state: present."
  ["missing_web1"]="Entry '10.30.0.11 web1' is missing from /etc/hosts on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["missing_web2"]="Entry '10.30.0.12 web2' is missing from /etc/hosts on web1. Ensure all three entries are in your playbook."
  ["missing_bd1"]="Entry '10.30.0.13 bd1' is missing from /etc/hosts on web1. Ensure all three entries are in your playbook."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_lineinfile"]="Le playbook n'utilise pas lineinfile. Utilisez ansible.builtin.lineinfile avec path: /etc/hosts et state: present."
  ["missing_web1"]="L'entrée '10.30.0.11 web1' est absente de /etc/hosts sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["missing_web2"]="L'entrée '10.30.0.12 web2' est absente de /etc/hosts sur web1. Assurez-vous que les trois entrées sont dans votre playbook."
  ["missing_bd1"]="L'entrée '10.30.0.13 bd1' est absente de /etc/hosts sur web1. Assurez-vous que les trois entrées sont dans votre playbook."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "lineinfile" "$pb_path"; then
  echo "$(get_message no_lineinfile)"; exit 0
fi

hosts_content=$(ansible web1 -i "$inventory" -m command -a "cat /etc/hosts" --become 2>/dev/null)

if ! echo "$hosts_content" | grep -q "10.30.0.11.*web1"; then
  echo "$(get_message missing_web1)"; exit 0
fi

if ! echo "$hosts_content" | grep -q "10.30.0.12.*web2"; then
  echo "$(get_message missing_web2)"; exit 0
fi

if ! echo "$hosts_content" | grep -q "10.30.0.13.*bd1"; then
  echo "$(get_message missing_bd1)"; exit 0
fi

echo '{"result": "0"}'
