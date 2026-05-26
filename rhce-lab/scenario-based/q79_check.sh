#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

pb_path="/home/ansible_user/workspace/dev_group.yml"
inventory="/home/ansible_user/workspace/inventory"

declare -A messages_en=(
  ["no_file"]="Playbook not found at $pb_path. Create it first."
  ["no_group_module"]="The playbook does not use the 'group' module. Add a task with ansible.builtin.group to create the developers group."
  ["no_append"]="The user task is missing 'append: yes'. Without it, adding groups replaces all existing memberships — always use append: yes."
  ["no_group_on_host"]="The 'developers' group does not exist on web1. Run the playbook: ansible-playbook -i $inventory $pb_path"
  ["not_member"]="john is not a member of the developers group on web1. Check that your user task sets groups: developers and append: yes."
)
declare -A messages_fr=(
  ["no_file"]="Playbook introuvable à $pb_path. Créez-le d'abord."
  ["no_group_module"]="Le playbook n'utilise pas le module 'group'. Ajoutez une tâche avec ansible.builtin.group pour créer le groupe developers."
  ["no_append"]="La tâche user n'a pas 'append: yes'. Sans cela, l'ajout de groupes remplace toutes les appartenances existantes — utilisez toujours append: yes."
  ["no_group_on_host"]="Le groupe 'developers' n'existe pas sur web1. Exécutez le playbook : ansible-playbook -i $inventory $pb_path"
  ["not_member"]="john n'est pas membre du groupe developers sur web1. Vérifiez que votre tâche user définit groups: developers et append: yes."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

if [ ! -f "$pb_path" ]; then
  echo "$(get_message no_file)"; exit 0
fi

if ! grep -q "group:" "$pb_path" && ! grep -q "ansible.builtin.group" "$pb_path"; then
  echo "$(get_message no_group_module)"; exit 0
fi

if ! grep -q "append" "$pb_path"; then
  echo "$(get_message no_append)"; exit 0
fi

group_result=$(ansible web1 -i "$inventory" -m command -a "getent group developers" --become 2>/dev/null)
if ! echo "$group_result" | grep -q "rc=0"; then
  echo "$(get_message no_group_on_host)"; exit 0
fi

id_result=$(ansible web1 -i "$inventory" -m command -a "id john" --become 2>/dev/null)
if ! echo "$id_result" | grep -q "developers"; then
  echo "$(get_message not_member)"; exit 0
fi

echo '{"result": "0"}'
