#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/shared_dir.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_file_module"]="The playbook does not use the 'file' module. Use ansible.builtin.file with state: directory and mode: '02775'."
  ["no_dir"]="/srv/devproject does not exist on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["wrong_group"]="/srv/devproject exists but is not owned by the 'developers' group on web1. Set group: developers in your file task."
  ["no_setgid"]="/srv/devproject exists but the setgid bit is not set on web1. Use mode: '02775' — the leading '2' sets the setgid bit."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_file_module"]="Le playbook n'utilise pas le module 'file'. Utilisez ansible.builtin.file avec state: directory et mode: '02775'."
  ["no_dir"]="/srv/devproject n'existe pas sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["wrong_group"]="/srv/devproject existe mais n'appartient pas au groupe 'developers' sur web1. Définissez group: developers dans votre tâche file."
  ["no_setgid"]="/srv/devproject existe mais le bit setgid n'est pas défini sur web1. Utilisez mode: '02775' — le '2' initial définit le bit setgid."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "file:" "$pb_path" && ! grep -q "ansible.builtin.file" "$pb_path"; then
  echo "$(get_message no_file_module)"; exit 0
fi

stat_result=$(ansible web1 -i "$inventory" -m stat -a "path=/srv/devproject" --become 2>/dev/null)
if ! echo "$stat_result" | grep -q '"exists": true'; then
  echo "$(get_message no_dir)"; exit 0
fi

group_result=$(ansible web1 -i "$inventory" -m command -a "stat -c '%G' /srv/devproject" --become 2>/dev/null)
if ! echo "$group_result" | grep -q "developers"; then
  echo "$(get_message wrong_group)"; exit 0
fi

mode_result=$(ansible web1 -i "$inventory" -m command -a "stat -c '%a' /srv/devproject" --become 2>/dev/null)
if ! echo "$mode_result" | grep -q "2775"; then
  echo "$(get_message no_setgid)"; exit 0
fi

echo '{"result": "0"}'
